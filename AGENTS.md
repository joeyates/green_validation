This is a CLI application written in Elixir.

<ProjectInformation>

See the following files for more information about the project:

- `README.md`: Project overview
</ProjectInformation>

<Development>
- Use relevant checks to ensure high-quality code (see below).
- Write tests for new code.
</Development>

<GitCommits>
- Only commit when all checks pass.
- Never use `git add -A`, instead, add moodified tracks by name.
- Write a clear and concise commit message of 50 characters or less in the imperative mood.
- Include a more detailed description in the commit body, if necessary.
- Wrap the body at 72 characters.
- Do not prefix commit messages as with Conventional Commits.
- Make atomic commits, where possible.
- Do not add `Co-Authored-By` trailers.
</GitCommits>

<Plans>
- Plans are stored in `docs/plans`.
- Unless instructed otherwise, create a branch for each plan.
- Implement one task at a time, then wait for review.
- Only commit when the user accepts that the task is complete.
- Mark tasks as complete in the plan file before committing.
- Use task names as commit messages.
- Avoid combining multiple tasks into a single commit.
- Unless otherwise instructed, stop after completing each task and wait for further instructions.
</Plans>

<Checks>
- `mix format --check-formatted` - Ensure Elixir code follows formatting rules
- `mix test` - Run tests to ensure code correctness
</Checks>
