<?php
  //simple pre-shared key, used for validity check
  $psk = md5('What a journey');
  //date time for timestamps
  date_default_timezone_set("America/New_York");
  //if sumbit is posted
  if ($_SERVER["REQUEST_METHOD"] == "POST") {
	//check if the system_hash is valid
	if (md5($psk.$_POST["uuid"]) == $_POST["system_hash"]) {
	  //open the file for the system_hash, create if not found
	  $results = fopen("/srv/data/".$_POST["system_hash"].".txt", "a");
	  //write the results
	  fwrite($results, "date_time ".date("Y/m/d H:i:s")."\n"); 
	  fwrite($results, "system_hash ".$_POST["system_hash"]."\n");
	  fwrite($results, "uuid ".$_POST["uuid"]."\n");
	  fwrite($results, "device_id ".$_POST["device_id"]."\n");
	  fwrite($results, "cpu_model ".$_POST["cpu_model"]."\n");
	  fwrite($results, "cpu_sig ".$_POST["cpu_sig"]."\n");
	  fwrite($results, "cpu_arch ".$_POST["cpu_arch"]."\n");
	  fwrite($results, "memory ".$_POST["memory"]."\n");
	  fwrite($results, "aes_inst ".$_POST["aes_inst"]."\n");
	  fwrite($results, "aes_bench ".$_POST["aes_bench"]."\n");
	  fwrite($results, "flops_bench ".$_POST["flops_bench"]."\n");
	  //separate successive results from the same system
	  fwrite($results, $result . "\n\n");
	  //close the file, announce success
	  fclose($results);
	  echo "Submit successful!";
	} else {
	  echo "Submit failed, invalid system_hash.";
	}
  }
?>
<!DOCTYPE html>
<html>
  <body>
    <form method="post" action="<?php echo $_SERVER['PHP_SELF'];?>">
	  system_hash <input type="text" name="system_hash"><br>
	  uuid <input type="text" name="uuid"><br>
	  device_id <input type="text" name="device_id"><br>
	  cpu_model <input type="text" name="cpu_model"><br>
	  cpu_sig <input type="text" name="cpu_sig"><br>
	  cpu_arch <input type="text" name="cpu_arch"><br>
	  memory <input type="text" name="memory"><br>
	  aes_inst <input type="text" name="aes_inst"><br>
	  aes_bench <input type="text" name="aes_bench"><br>
	  flops_bench <input type="text" name="flops_bench"><br>
      <input type="submit">
    </form>
  </body>
</html>