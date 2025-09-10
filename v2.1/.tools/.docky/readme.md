How does docky work?

Docky is simple bash script that should act as an assistant for non-beginner docker users. Basically, it has some useful commands
that one can run in order to make their life easier. If a user doesn't have experience with docker, user can run some simple commands
that will help the user to get started with this package. 

Docky is simple assistant whose main goal is to provide assitance with docker compose file along with other helpful.
Primary goal is to add the docker services and run the app. One can generate new docker compose file if not exists by running .docker/v2/docky gen.

So basically this package is a setup for setting a docker enviornment in any project. Suppose you have a project web app and you 
want to run and develop this project in docker wihtout installing any dependencies on your local machine. You can use this package and you just have to add 
this package as a git submodule in your project. After that you can run the command .docker/v2/docky gen to generate a docker compose file.
Where .docker is the folder name of submodule and v2 is the second version of this package. After that you can run the command .docker/v2/docky up to start the docker services.
So from the main project web app, one can execute our docky script to manage the docker services.

In our this package we provide some stubs for starting and i have planned to add more stubs in future. 
Currrently, docky would read the stubs from .docker/v2/stubs and see what we have and then it will add the service in docker composer.

Docky uses yq to manipulate the yaml files. Basically, if user is geneating the docker compose file, it will add the app.yml for the first time.
Then later user can run the command .docker/v2/docky add-svc <service-name> to add more services, in this case docky will merge the exisitng docker compose file
with the new service stub file without effecting the exisitng services in the docker compose file. This is important, it should now touch the exisitng services in docker compose file.

The stub also contains the some prefix variables like $DOCKY_REPLACE_NETWORK_NAME, and this should be parsed before merging from the stub files.
All the substituable variable start with $DOCKY_REPLACE_ and then the variable name. This is important to avoid any conflict with the other variables in the stub files.
in this case, docky will prompt in stdin to ask the user to provide the value for the variable, in this case it will ask for the network name and
then it will replace the variable with the user provided value.

we would remove the docky.yml file which i have added for the default variables but this didn't work i have expacted. 

