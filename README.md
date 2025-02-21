# ./steampunk_setup.sh

1. **Ensure Prerequisites Are Installed:**
   - **[Node.js & npm](https://nodejs.org/en/):** Download and install Node.js (npm is included).
   - **[Git](https://git-scm.com/):** Install and configure Git.
   - **[GitHub CLI (`gh`)](https://cli.github.com/):** Install and authenticate by running:

     ```bash
     gh auth login
     ```

   - **SSH Key:** Ensure you have an SSH key. If not, follow [GitHub's guide on generating an SSH key](https://docs.github.com/en/authentication/connecting-to-github-with-ssh).

2. **Prepare the Environment:**
   - Create a `.env` file in the same directory as the script with:

     ```bash
     APP_NAME=YourAppName
     GITHUB_ACCOUNT=YourGitHubUsername
     ```

   - Ensure your working directory is not inside another Git repository (if it is, the script will automatically move up one level).

3. **Run the Script:**
   - Save the script as `steampunk_setup.sh`.
   - Make it executable:

     ```bash
     chmod +x steampunk_setup.sh
     ```

   - Execute the script:

     ```bash
     ./steampunk_setup.sh
     ```

4. **Post-Execution Checks:**
   - Review the console output and `steampunk_setup.log` for errors.
   - Confirm that:
     - A new Vite + React (TypeScript) project was created in a folder named after your `APP_NAME`.
     - A new Git repository was initialized, committed, and pushed to GitHub.
     - The project was deployed to GitHub Pages (URL printed at the end).
     - Storybook was initialized and auto-launched.

5. **Integration & Maintenance:**
   - Verify that the generated configuration files (for Tailwind, PostCSS, Vite, Storybook) meet your project’s standards.
   - Integrate custom changes carefully, adhering to your codebase’s best practices.
   - Continue using version control and thorough testing to maintain high code quality.

Following these steps with the provided active links will ensure a smooth setup and seamless integration with your existing system. Happy coding!
