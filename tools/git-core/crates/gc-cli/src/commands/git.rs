use clap::{Args, Subcommand};
use gc_core::ports::SystemPort;
use console::style;

#[derive(Args, Debug)]
pub struct GitArgs {
    #[command(subcommand)]
    pub command: GitCommands,
}

#[derive(Subcommand, Debug)]
pub enum GitCommands {
    /// Show git status with context
    Status,
    /// Show git log
    Log {
        #[arg(short, long, default_value = "5")]
        limit: usize,
    },
}

pub async fn execute(
    args: GitArgs,
    system: &impl SystemPort,
) -> color_eyre::Result<()> {
    match args.command {
        GitCommands::Status => {
            println!("{}", style("📊 Git Status").bold());
            system.run_command("git", &["status".to_string()]).await?;
        }
        GitCommands::Log { limit } => {
            println!("{}", style("📜 Git Log").bold());
            system.run_command("git", &["log".to_string(), "--oneline".to_string(), format!("-{}", limit)]).await?;
        }
    }
    Ok(())
}
