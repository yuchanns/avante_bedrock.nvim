use std::{fs::copy, path::PathBuf, process::Command};

use anyhow::Result;
use glob::glob;

#[test]
fn test_lua() -> Result<()> {
    assert!(Command::new("cargo").arg("build").status()?.success());
    let manifest_dir = env!("CARGO_MANIFEST_DIR");
    assert!(copy(
        format!("{manifest_dir}/target/debug/liblua_reqsign_aws.so"),
        format!("{manifest_dir}/target/debug/reqsign_aws.so")
    )
    .is_ok());

    let pattern = "tests/**/*_test.lua";
    let lua_files: Vec<PathBuf> = glob(pattern)?.filter_map(Result::ok).collect();
    for file in &lua_files {
        assert!(Command::new("luajit")
            .env("LUA_CPATH", format!("{manifest_dir}/target/debug/?.so;;"))
            .env("LUA_PATH", format!("{manifest_dir}/tests/?.lua;;"))
            .arg(file.as_path())
            .status()?
            .success());
    }

    Ok(())
}
