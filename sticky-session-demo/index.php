<html>
	<head><title>Sticky Cookie Session Demo</title></head>
	<body style="font-family: helvetica;">
		<div style="margin: auto; text-align: center;">
			<br><br>
			<h1>Sticky Cookie Session Demo</h1>
			<br><br>
			<?php

				// Cookie value is not significant
				setcookie("MY_COOKIE", "value");

				echo "<p>The job you have reached is:</p>";
				echo "<h3>" . getenv('CNTM_JOB_FQN') . "<h3>";
				echo "<h2>Instance: " . getenv('CNTM_INSTANCE_UUID') . "</h2>";

			?>
			<button onclick="reloadPage()">Reload page</button>
			<script>function reloadPage() { location.reload(); }</script>
		</div>
	</body>
</html>