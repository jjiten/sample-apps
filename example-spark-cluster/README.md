# Build Spark cluster using Apcera packages

*Follow the steps for building a spark cluster on Apcera platform:*

1. Execute following commands to build packages
 ```
 a. jdk-1.8 : apc package build --name jdk-1.8 jdk-build.conf
 b. spark-2.1.1 : apc package build --name spark-2.1.1 spark-build.conf
 c. spark-apcera : apc package build --name spark-apcera spark-apcera-build.conf 
```

**Note:** For building spark-apcera package make sure *start-slave.sh* and *start-master.sh* scripts are present in the working directory.

2. You can check if the packages are successfully built and imported using 
```
   apc package list
```
3. Replace the cluster domain with your cluster in *sparknet-create.sh* script 
```   
   export ROUTE_BASE=<your-cluster-domain without http/https> 
```
execute the sparknet-create.sh script to create a virtual network "./sparknet-create.sh" 

4. To check whether the spark-cluster is created, run command. It should show master and slave apps
```
apc app list 
```

5. Login into the console and see the network details. You can see master and slave added to the network 
**OR**
Use APC to see the list of apps added to the network
```
apc network show sparknet 
```
*Note down the master-ip for further steps.* 

6. Connect to the master app 
```
apc app connect spark-m
``` 
After connecting successfully to the app, go to directory "**cd $SPARK_HOME/bin**" and initiate the spark-shell
```
./spark-shell --master spark://<master-ip>:7077 --conf spark.driver.host=<master-ip>
```
This will land the user into spark shell. Execute command to test if the shell and thus the spark-cluster works fine. 
```
sc.parallelize(1 to 1000).count()
```
This should return **res0: Long = 1000** as the output.

7. Corresponding logs can be seen on the worker which shows that master is communicating to slave. To see logs 
via web console, go to **Jobs -> Apps -> spark-s1/spark-s2 (workers) -> Logs**   
OR via APC 
```
apc app logs spark-s1 
apc app logs spark-s2
```

# Build Spark cluster using Docker images 

1. Create two apps, Spark Master and Spark Slave (you can create multiple workers) 
```   
   apc docker run master -i apcerademos/spark -it
   apc docker run slave -i apcerademos/spark -it
```
2. Create a virtual network and add all the jobs to it

```
   apc network create sparknet
   apc network join sparknet --job master
   apc network join sparknet --job slave
```

3. Connect to both the apps using "apc app connect app-name" in different terminals 

**Note:** Make sure SSH is enabled for both. To enable SSH use "apc app update app-name --allow-ssh"

4. Go to "**cd $SPARK_HOME/sbin**" directory and enable master and slave mode respectively. To enable the mode
```
   Master: ./start-master.sh -h $VIRTUAL_NETWORK_IP
   Slave : ./start-slave.sh -h $VIRTUAL_NETWORK_IP $SPARK_MASTER
```

 
**Note**: **$VIRTUAL_NETWORK_IP** can be retrieved by executing 
"ifconfig | grep "inet addr" | cut -d: -f2 | grep -v "169." | grep -v "127.0.0.1" | cut -d ' ' -f1" 
inside the master/slave app and **$SPARK_MASTER** is the IP of the master.

5. To test whether the spark cluster is working fine, follow steps 6 and 7 from the above section.