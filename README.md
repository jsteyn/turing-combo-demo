# turing-combo-demo

This demo combines autoprognosis and MLFlow by using two docker containers.


Before running the command to create the containers, edit the docker-compose file
and update the paths according to your environment.

To create the containers run:
```docker-compose up -d```

The command will pull the required images from DockerHub. Once you have created the
images you can copy the example notebook into Jupyter Notebok.

MLFlow is served on port 5000 and is in one container. The AutoPrognosis environment
is in the second container, serving Jupyter Notebook on port 8080.
