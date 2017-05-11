# Dotnet Runtime Package and Stager
This directory contains a dotnet runtime package and a custom dotnet stager that can be used to stage .NET Core and ASP.NET Core applications to Apcera.  I've also included a barebones sample ASP.NET Core application and instructions on how to create it.

## Dotnet Runtime Package
The dotnet-core-sdk-1.0.1-ubuntu-14.04 runtime package is created from the file [dotnet-core-sdk-1.0.1-ubuntu-14.04.conf](./sdk/dotnet-core-sdk-1.0.1-ubuntu-14.04.conf) with the command `apc package build dotnet-core-sdk-1.0.1-ubuntu-14.04.conf`. It requires a package providing the os.ubuntu dependency which any Apcera cluster should have. It will be placed in the /apcera/pkg/runtimes namespace. It provides the following dependencies: dotnet-core, dotnet-core-1.0.1, dotnet-core-ubuntu, dotnet-core-1.0.1-ubuntu, and dotnet-core-1.0.1-ubuntu-14.04. As suggested by its name, it includes the .NET Core SDK which includes the .NET Core runtime. (This is analogous to a Java JDK including the Java JRE.)

The package script uses apt-get to install dotnet-dev-1.0.1.

## Dotnet Stager and Staging Pipeline
I created the custom dotnet [stager](./stager/dotnet_stager.rb) and staging pipeline using the [Ruby Library for the Apcera Stager API](https://docs.apcera.com/api/stager-api-lib/). Two additional files, Gemfile and Gemfile.lock, are also needed for the actual running of the stager which is written in Ruby. The stager downloads the contents of your current directory and then determines whether the current directory contains a file ending in ".csproj" or ".deps.json". In the former case, you are staging the source code for a .NET Core application; in the latter case, you are staging the published DLLs for a .NET Core application.

The commands to create the dotnet stager and staging pipeline are:
```console
apc stager create /apcera/stagers::dotnet --start-command="./dotnet_stager.rb" --staging=/apcera::ruby \
    --allow-egress
apc staging pipeline create /apcera/stagers::dotnet --name /apcera::dotnet
```
Note that this creates the staging pipeline in the /apcera namespace and the stager in the /apcera/stagers namespace, conforming to what is done for Apcera's standard staging pipelines and stagers.

### Start Commands
When staging source code, we set the start command to `dotnet restore ; dotnet run`. If running dotnet restore each time you start the app takes too long, I recommend that you stage your published DLLs instead. When staging published .NET DLLs, we set the start command to `dotnet <app_name>.dll` where \<app_name\> matches the prefix of the .deps.json file.

### Why No Dotnet Dependency Is Included
In the first version of the dotnet stager, I actually included the dotnet-core dependency provided by the dotnet-core-sdk-1.0.1-ubuntu-14.04 runtime package. However, the first customer who tested the stager wanted the flexibility to base their .NET apps on various standard .NET Docker images as well as on runtime packages like the one I had created. To give customers more flexibility, I removed the dotnet-core dependency from the stager. This does have the consequence, however, that customers must specify their own dotnet dependency with the `--depends-on` or `-do` option of the `apc app create` command or in the package_dependencies section of a continuum.conf application manifest.

### Example of Staging an Application with the Dotnet Stager
Here is an example of staging applications with the dotnet stager using the dotnet-core-sdk-1.0.1-ubuntu-14.04 package:

First, you'll want to install .NET Core on your computer and then create a simple ASP.NET Core app.  To install .NET Core, see https://www.microsoft.com/net/core and select Windows, Linux, or Mac. After intalling it, you can create an ASP.NET Core MVC application in an empty directory with the command:
```console
dotnet new mvc --auth None --framework netcoreapp1.1
```
You might then want to customize the HomeController.cs file under the Controllers directory and some of the files under the Views directory.  I've actually included a slightly modified ASP.NET Core [app](./AspNetSample) in this repository.

If you want to stage your source code, run the `apc app create` command from the top-level directory of your .NET Core project (the one with a csproj file). If you want to stage from DLLs, first run `dotnet restore` and then run `dotnet publish -c Release` and then navigate to the sub-directory containing your DLLs, bin/Release/netcoreapp1.1/publish.

In either case, here are the commands to actually create, configure, and start your ASP.NET Core application:
```console
apc app create aspnet-sample --staging=/apcera::dotnet --disable-routes --allow-egress --env-set \
    'ASPNETCORE_URLS=http://*:5000' --user root -do runtime.dotnet-core-ubuntu
apc app update aspnet-sample --port-add 5000
apc route add http://aspnet-sample.<your_cluster> --app aspnet-sample --port 5000
apc app start aspnet-sample
```
There are 3 important things to note about this sequence of commands:

1. The user of the app *must* be set to root for the .NET Core or ASP.NET Core app to run correctly.
1. The ASPNETCORE_URLS environment variable should be set for ASP.NET Core apps so that the apps listen on the desired IP and port.
1. You should replace \<your_cluster\> with the actual name of your Apcera cluster.

Alternatively, you could specify most of the needed information in a continuum.conf application manifest like the [one](./AspNetSample/continuum.conf) included here. In this case, you would replace the above commands with the following single command after placing the continuum.conf manifest in the directory where you run the command and editing it to specify the correct cluster in the included route:
```console
apc app create --user root
```
The only thing you still need to specify on the command line is that the user will be root.

### Exporting and Importing the Dotnet Staging Pipeline and Stager
If desired, you can export the staging pipeline and stager from one Apcera cluster and import them into another using these commands:
```console
apc staging pipeline export /apcera::dotnet
apc package import dotnet.cntmp
```
The export actually includes both the staging pipeline and the stager in the cntmp file. Importing the package creates both the staging pipeline and the stager in the correct locations.

## Other .NET Packages
There are multiple standard .NET Docker images which you might prefer to use in various circumstances instead of the runtime package I created.  If so, you can pull those images into Apcera as new packages and stage applications using them and the dotnet stager described above.

Here are commands to illustrate this. Note that we first set the current namespace to /apcera/pkg/rumtimes so that the .NET packages are created in that namespace. In addition to pulling the Docker images into Apcera as packages, we also update the packages to indicate which dotnet dependencies they provide.
```console
apc namespace /apcera/pkg/runtimes

apc docker pull microsoft-dotnet-1.1.1-runtime --image microsoft/dotnet:1.1.1-runtime
apc package update microsoft-dotnet-1.1.1-runtime --provides-add runtime.dotnet-core
apc package update microsoft-dotnet-1.1.1-runtime --provides-add runtime.dotnet-runtime-1.1.1

apc docker pull microsoft-dotnet-1.1.1-sdk --image microsoft/dotnet:1.1.1-sdk
apc package update microsoft-dotnet-1.1.1-sdk --provides-add runtime.dotnet-core
apc package update microsoft-dotnet-1.1.1-sdk --provides-add runtime.dotnet-sdk-1.1.1

apc docker pull microsoft-aspnetcore-1.1.1 --image microsoft/aspnetcore:1.1.1
apc package update microsoft-aspnetcore-1.1.1 --provides-add runtime.dotnet-core
apc package update microsoft-aspnetcore-1.1.1 --provides-add runtime.aspnetcore-1.1.1

apc docker pull microsoft-aspnetcore-build-1.1.1 --image microsoft/aspnetcore-build:1.1.1
apc package update microsoft-aspnetcore-build-1.1.1 --provides-add runtime.dotnet-core
apc package update microsoft-aspnetcore-build-1.1.1 --provides-add runtime.aspnetcore-build-1.1.1
```
And here are some examples of using the custom dotnet stager to stage apps that use some of these .NET Docker images:

From the microsoft-dotnet-1.1.1-runtime package:
```console
apc app create aspnet-with-dep-dotnet-runtime-1.1.1 --staging=/apcera::dotnet --disable-routes \
    --allow-egress --env-set 'ASPNETCORE_URLS=http://*:5000' --user root -do runtime.dotnet-runtime-1.1.1
apc app update aspnet-with-dep-dotnet-runtime-1.1.1 --port-add 5000
apc route add http://aspnet-with-dep-dotnet-runtime-1.1.1.demo.apcera.net --app \
    aspnet-with-dep-dotnet-runtime-1.1.1 --port 5000
apc app start aspnet-with-dep-dotnet-runtime-1.1.1
```

From the microsoft-aspnetcore-1.1.1:
```console
apc app create aspnet-with-dep-aspnetcore-1.1.1 --staging=/apcera::dotnet --disable-routes \
    --allow-egress --env-set 'ASPNETCORE_URLS=http://*:5000' --user root -do runtime.aspnetcore-1.1.1
apc app update aspnet-with-dep-aspnetcore-1.1.1 --port-add 5000
apc route add http://aspnet-with-dep-aspnetcore-1.1.1.demo.apcera.net --app \
    aspnet-with-dep-aspnetcore-1.1.1 --port 5000
apc app start aspnet-with-dep-aspnetcore-1.1.1
```
