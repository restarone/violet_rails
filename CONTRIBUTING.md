# Contributing to Violet Rails

## Developer environment setup

Getting started is easy as installing docker and then following the steps here: https://github.com/restarone/violet_rails/wiki/Getting-started-(development-cheatsheet)

## Grab your own copy

Fork the repository and work on your feature!

## Open a pull request 
Open a pull request targeting `restarone/violet_rails:master` 
example: https://github.com/restarone/violet_rails/pull/1461

### Pull Request Checklist

#### 1. Required CI tests are passing ✔️
Your code cannot be merged if it breaks existing functionality
<img width="642" alt="Screen Shot 2023-03-28 at 6 35 00 AM" src="https://user-images.githubusercontent.com/35935196/228210025-cdc7bcb8-0f7e-4172-a6a0-ef493cbcf18a.png">

#### 2. Description references the issue 
Description references the issue the PR aims to fix. Includes a demo video if its a new feature or bug fix
<img width="721" alt="Screen Shot 2023-03-28 at 6 37 03 AM" src="https://user-images.githubusercontent.com/35935196/228210556-4fa74a40-5721-4be5-b9cf-5772caeb3590.png">

#### 3. Includes tests
Any new code paths added should be exercised with tests
<img width="1728" alt="Screen Shot 2023-03-28 at 6 41 26 AM" src="https://user-images.githubusercontent.com/35935196/228211530-4b22e172-3534-4084-b78e-f94f34c69856.png">

#### 4. Ready to merge

Merge conflicts should be resolved and the branch should be up-to-date with `master`
<img width="723" alt="Screen Shot 2023-03-28 at 6 50 34 AM" src="https://user-images.githubusercontent.com/35935196/228213563-04cde3df-050e-4ec3-bc41-f000e554f5e3.png">

## Code standards
Changes should include automated tests, Restarone Solutions Inc. reserves the right to deny any code change that may risk production Violet Rails applications.

## Testing and deployment
Once your pull request has a matching base branch on this repository, automated tests will run. If the automated tests are passing, we will launch a review app (which is a one-off ephemeral environment for testing your change in isolation) and evaluate the difference. If the change looks good on the review app, the change will be included in a release candidate which will be deployed to `restarone.solutions` for internal testing. Once internal testing and monitoring is complete, it will be merged to master.
