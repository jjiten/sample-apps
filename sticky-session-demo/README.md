## Sticky session cookie demo application

This PHP application demonstrates how to use sticky session cookies so that HTTP requests from a web browser are routed to the same back-end job instance. The demo app displays the values of the `CNTM_INSTANCE_UUID` and `CNTM_JOB_FQN` [environment variables](https://docs.apcera.com/jobs/envt-vars/) of the job instance handling the request. 

The PHP app sets a cookie named `MY_COOKIE` in its response, which matches the name of the sticky session cookie added to the app.

```php
<html>
    <head><title>Sticky Cookie Session Demo</title></head>
    <body style="font-family: helvetica;">
        <div style="margin: auto; text-align: center;">
            <br><br>
            <h1>Sticky Cookie Session Demo</h1>
            <br><br>
            <?php

                // Cookie value is not significant
                setcookie("MY_COOKIE", "cookie_value");

                echo "<p>The job you have reached is:</p>";
                echo "<h3>" . getenv('CNTM_JOB_FQN') . "<h3>";
                echo "<h2>Instance: " . getenv('CNTM_INSTANCE_UUID') . "</h2>";

            ?>
            <button onclick="reloadPage()">Reload page</button>
            <script>function reloadPage() { location.reload(); }</script>
        </div>
    </body>
</html>
```

## Deploying the demo app

To deploy the application run the following APC command, being sure to update the application's `--route` for your cluster's environment/domain: 

```bash
apc app create sticky-application  \
--sticky-session-cookies=MY_COOKIE \
--routes http://sticky-application.example.com \
--instances 10 \
--start
```

This starts the application with 10 instances and a sticky session cookie of `MY_COOKIE`. 

Open the application's route in a browser and note the value of the **Instance** field displayed on the we  page; this is the UUID of the job instance handling the request. Click the **Reload** button on the page repeatedly. You should notice that the displayed UUID value does not change, indicating that each request is being handled by the same job instance.

![](browser.png)

As a test, try removing the job's sticky session cookie with the following command:

```bash
apc application update sticky-application --no-sticky-session-cookies
```

Open the job's route in a new browser window or tab and repeatedly press the **Reload** button. In this case you should randomly see that the browser is connecting to a different job instance.