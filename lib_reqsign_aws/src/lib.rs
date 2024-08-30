use std::str::FromStr;

use http::Method;
use http::Request;
use mlua::{Error::RuntimeError, Lua, Result, Table};
use reqsign::{AwsCredential, AwsV4Signer};
use sha2::Digest;
use sha2::Sha256;

struct SignParams {
    access_key_id: String,
    secret_access_key: String,
    region: String,
    headers: Table,
    body: String,
    service: String,
    uri: String,
    method: String,
}

fn sign(l: &Lua, param: Table) -> Result<Table> {
    let params = SignParams {
        access_key_id: param.get("access_key_id")?,
        secret_access_key: param.get("secret_access_key")?,
        region: param.get("region")?,
        headers: param.get("headers")?,
        body: param.get("body")?,
        service: param.get("service")?,
        uri: param.get("uri")?,
        method: param.get("method")?,
    };
    let signer = AwsV4Signer::new(&params.service, &params.region);
    let credential = AwsCredential {
        access_key_id: params.access_key_id,
        secret_access_key: params.secret_access_key,
        ..Default::default()
    };
    let mut builder = Request::builder();
    for pair in params.headers.pairs::<String, String>() {
        let (key, value) = pair?;
        builder = builder.header(&key, &value);
    }
    let mut hasher = Sha256::new();
    hasher.update(params.body.as_bytes());
    let result = hasher.finalize();
    let result = hex::encode(result);
    builder = builder.header("x-amz-content-sha256", &result);
    let mut req = builder
        .uri(params.uri)
        .method(Method::from_str(&params.method).map_err(|e| RuntimeError(e.to_string()))?)
        .body(params.body)
        .map_err(|e| RuntimeError(e.to_string()))?;
    signer
        .sign(&mut req, &credential)
        .map_err(|e| RuntimeError(e.to_string()))?;
    let headers = req.headers();
    let table = l.create_table()?;
    for (key, value) in headers.iter() {
        table.set(key.as_str(), value.to_str().unwrap_or_default())?;
    }
    Ok(table)
}

#[mlua::lua_module]
pub fn reqsign_aws(lua: &Lua) -> Result<Table> {
    let module = lua.create_table()?;
    module.set("sign", lua.create_function(sign)?)?;
    Ok(module)
}

#[cfg(test)]
mod tests {
    use std::env::var;

    use anyhow::Result;
    use http::header::CONTENT_TYPE;
    use http::HeaderMap;
    use http::HeaderValue;
    use reqsign::AwsV4Signer;
    use reqwest::Client;
    use reqwest::Url;
    use serde_json::json;
    use sha2::Digest;
    use sha2::Sha256;

    #[tokio::test]
    async fn it_works() -> Result<()> {
        let client = Client::new();
        let signer = AwsV4Signer::new("bedrock", "us-east-1");
        let url = Url::parse(
            "https://bedrock-runtime.us-east-1.amazonaws.com/model/anthropic.claude-3-5-sonnet-20240620-v1:0/invoke",
        )?;
        let mut req = reqwest::Request::new(http::Method::POST, url);
        let body = json!({
            "anthropic_version": "bedrock-2023-05-31",
            "max_tokens": 4096,
            "messages": [
              {
                "role": "user",
                "content": "How to sign a bedrock http request without SDK\n"
              }
            ],
            "temperature": 0.6,
            "top_p": 1
        })
        .to_string();
        let mut hasher = Sha256::new();
        hasher.update(body.as_bytes());
        let result = hasher.finalize();
        let result = hex::encode(result);
        *req.body_mut() = Some(body.into());
        let mut headers = HeaderMap::new();
        headers.insert(CONTENT_TYPE, HeaderValue::from_static("application/json"));
        headers.insert("x-amz-content-sha256", HeaderValue::from_str(&result)?);
        *req.headers_mut() = headers;
        // Signing request with Signer
        let credential = reqsign::AwsCredential {
            access_key_id: var("AWS_ACCESS_KEY_ID")?,
            secret_access_key: var("AWS_SECRET_ACCESS_KEY")?,
            session_token: None,
            expires_in: None,
        };
        signer.sign(&mut req, &credential)?;
        // Sending already signed request.
        req.headers().iter().for_each(|(k, v)| {
            println!("{}: {}", k, v.to_str().unwrap());
        });
        let resp = client.execute(req).await?;
        assert_eq!(resp.status(), 200);
        println!("resp got body: {:?}", resp.text().await?);
        Ok(())
    }
}
