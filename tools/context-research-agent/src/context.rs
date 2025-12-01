use anyhow::Result;
use serde::Deserialize;
use std::collections::HashMap;
use std::path::Path;
use tokio::fs;

#[derive(Debug, Clone)]
pub struct Dependency {
    pub name: String,
    pub version: String,
    pub ecosystem: Ecosystem,
}

#[derive(Debug, Clone, PartialEq)]
pub enum Ecosystem {
    Rust,
    Node,
    Python,
}

#[derive(Deserialize)]
struct CargoToml {
    dependencies: Option<HashMap<String, toml::Value>>,
}

#[derive(Deserialize)]
struct PackageJson {
    dependencies: Option<HashMap<String, String>>,
    #[serde(rename = "devDependencies")]
    dev_dependencies: Option<HashMap<String, String>>,
}

pub async fn analyze_workspace(root: &Path) -> Result<Vec<Dependency>> {
    let mut deps = Vec::new();
    
    // Recursively find all manifest files
    let manifest_files = find_manifest_files(root).await?;
    
    for manifest_path in manifest_files {
        let filename = manifest_path.file_name()
            .and_then(|n| n.to_str())
            .unwrap_or("");
        
        match filename {
            "Cargo.toml" => {
                if let Ok(content) = fs::read_to_string(&manifest_path).await {
                    if let Ok(cargo) = toml::from_str::<CargoToml>(&content) {
                        if let Some(d) = cargo.dependencies {
                            for (name, val) in d {
                                let version = match val {
                                    toml::Value::String(s) => s,
                                    toml::Value::Table(t) => t.get("version")
                                        .and_then(|v| v.as_str())
                                        .unwrap_or("*")
                                        .to_string(),
                                    _ => "*".to_string(),
                                };
                                // Skip workspace/path dependencies
                                if !version.contains("path") && !version.contains("workspace") {
                                    deps.push(Dependency {
                                        name,
                                        version,
                                        ecosystem: Ecosystem::Rust,
                                    });
                                }
                            }
                        }
                    }
                }
            }
            "package.json" => {
                if let Ok(content) = fs::read_to_string(&manifest_path).await {
                    if let Ok(pkg) = serde_json::from_str::<PackageJson>(&content) {
                        if let Some(d) = pkg.dependencies {
                            for (name, version) in d {
                                deps.push(Dependency { name, version, ecosystem: Ecosystem::Node });
                            }
                        }
                        if let Some(d) = pkg.dev_dependencies {
                            for (name, version) in d {
                                deps.push(Dependency { name, version, ecosystem: Ecosystem::Node });
                            }
                        }
                    }
                }
            }
            _ => {}
        }
    }
    
    // Deduplicate by name (keep first occurrence)
    let mut seen = std::collections::HashSet::new();
    deps.retain(|d| seen.insert(d.name.clone()));

    Ok(deps)
}

async fn find_manifest_files(root: &Path) -> Result<Vec<std::path::PathBuf>> {
    let mut manifests = Vec::new();
    let mut dirs_to_check = vec![root.to_path_buf()];
    
    while let Some(dir) = dirs_to_check.pop() {
        if let Ok(mut entries) = fs::read_dir(&dir).await {
            while let Ok(Some(entry)) = entries.next_entry().await {
                let path = entry.path();
                let name = entry.file_name();
                let name_str = name.to_str().unwrap_or("");
                
                // Skip hidden dirs, node_modules, target, .git
                if name_str.starts_with('.') || 
                   name_str == "node_modules" || 
                   name_str == "target" {
                    continue;
                }
                
                if path.is_dir() {
                    dirs_to_check.push(path);
                } else if name_str == "Cargo.toml" || name_str == "package.json" {
                    println!("  📄 Found: {}", path.display());
                    manifests.push(path);
                }
            }
        }
    }
    
    Ok(manifests)
}