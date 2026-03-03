# Plans

This directory contains plans - instructions for a coding agent to follow.

Each plan is ordered by number, and completed plans are renamed with a `_done` suffix.
For example, `0001_foo.md` becomes `0001_foo_done.md` when completed.

The plans are written in markdown format and should include the following XML tags:

* `<title>`: A brief title describing the plan.
* `<description>`: A detailed description of the plan, including the problem statement and the proposed
solution.
* `<branch>`: The name of the git branch where the implementation will take place.
* `<overview>`: A high-level overview of the plan, outlining the main goals and objectives.
* `<tasks>`: A list of specific tasks that need to be completed to implement the plan.
  Each task is preceded by a checkbox to track progress.
* `<principal_files>`: A list of the main files that will be involved in the implementation,
  including input files, intermediate files, and output files.
* `<acceptance_criteria>`: A list of criteria that must be met for the plan to be considered complete and successful.

