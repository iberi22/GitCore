use clap::{Args, Subcommand};
use gc_core::ports::{GitHubPort, SystemPort};
use console::style;

#[derive(Args, Debug)]
pub struct IssueArgs {
    #[command(subcommand)]
    pub command: IssueCommands,
}

#[derive(Subcommand, Debug)]
pub enum IssueCommands {
    /// List issues
    List {
        /// Filter by state (open, closed, all)
        #[arg(short, long, default_value = "open")]
        state: String,

        /// Filter by assignee
        #[arg(short, long)]
        assignee: Option<String>,

        /// Filter by assigned to me
        #[arg(long)]
        assigned_to_me: bool,

        #[arg(short, long, default_value = "10")]
        limit: usize,
    },
}

pub async fn execute(
    args: IssueArgs,
    github: &impl GitHubPort,
    system: &impl SystemPort,
) -> color_eyre::Result<()> {
    match args.command {
        IssueCommands::List { state, assignee, assigned_to_me, limit } => {
            // Detect repo
            let output = system.run_command_output("git", &["remote", "get-url", "origin"].map(|s| s.to_string())).await?;
            let (owner, repo) = parse_repo_from_url(&output)?;

            println!("{}", style(format!("Fetching issues for {}/{}...", owner, repo)).dim());

            let current_user;
            let effective_assignee: Option<String> = if assigned_to_me {
                current_user = github.check_auth().await?;
                Some(current_user)
            } else {
                assignee.clone()
            };

            let issues = github.list_issues(&owner, &repo, Some(state.clone()), effective_assignee).await?;

            if issues.is_empty() {
                println!("No issues found.");
                return Ok(());
            }

            for issue in issues.iter().take(limit) {
                let labels = issue.labels.join(", ");
                println!("#{} {} {} {}",
                    style(issue.number).green().bold(),
                    issue.title,
                    style(&issue.state).dim(),
                    if !labels.is_empty() { style(format!("[{}]", labels)).blue() } else { style("".to_string()) }
                );
            }
        }
    }
    Ok(())
}

fn parse_repo_from_url(url: &str) -> color_eyre::Result<(String, String)> {
    let url = url.trim();
    // Supports:
    // https://github.com/owner/repo.git
    // git@github.com:owner/repo.git

    let parts: Vec<&str> = if url.starts_with("git@") {
        url.split(':').nth(1).unwrap_or("").split('/').collect()
    } else {
        url.split("github.com/").nth(1).unwrap_or("").split('/').collect()
    };

    if parts.len() < 2 {
        return Err(color_eyre::eyre::eyre!("Could not parse repo from URL: {}", url));
    }

    let owner = parts[0].to_string();
    let repo = parts[1].trim_end_matches(".git").to_string();

    Ok((owner, repo))
}
