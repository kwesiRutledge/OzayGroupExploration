# OzayGroupExploration
Some of the code that I use to explore ideas (Model Checking, Game Theory, etc.) while a member of the Özay Group at the University of Michigan.

## Setting Up Your Own Virtual Environment

To cretate a virtual environment, use Python 3's built-in venv keyword as follows:
``` python3 -m venv /path/to/virtual/environment/ ```

To start the virtual environment stored at a location `test_env` in the current directory run:
``` source test_env/bin/activate ```

To deactivate a virtual environment, at any time while the environment is activated run `deactivate` from the same terminal.

## Using Kinova

### Building Drake-Kinova Docker Image and Running a Container with it

In order to control the 6 Degree of Freedom Kinova Gen3 in the Özay group, I use Drake along with the Kinova Kortex API and kinova_drake (a library built by Vince Kurtz).

If you are interested in getting set up with all of the software that you need to control our robot, do the following:
1. Pull this git repository.
2. From the repository's main directory, run a shell script to create the docker image: `./shell-scripts/create-drake-v2-docker-image.sh`.
3. Start the docker container: `./shell-scripts/run-drake-v2-docker-container.sh`

### Developing Code for Kinova

Make sure that the container named drake-container is running, use an editor like VS Code to begin developing.

In VS Code, you can attach your application to the running container, giving you access to all of the libraries installed in the container after you built it.