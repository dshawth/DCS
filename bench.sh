#!/bin/bash

#Author: Daniel Hawthorne

echo -e "\nBenchmark script starting in 10 seconds."
echo -e "Press Ctrl+C to exit to Terminal.\n"

sleep 10
echo "Script started!"
echo -n "Setting up environment. "; sleep 1

test_url="http://www.google.com"
#collection server url, may change if taken offline
collection_server="http://ec2-107-21-89-87.compute-1.amazonaws.com"
#psk for validity check
psk=$(echo -n 'What a journey' | md5sum | awk '{print $1}')
#usb device_id
device_id=$(lsblk -d -o name,label,serial | \
  grep ARCH_201805 -m 1 | awk '{print $3}')

#check the connection
echo -ne "Done!\nChecking connection. "; sleep 1
conn=$(curl -s -I --retry 5 --retry-connrefused --url $test_url)

if [[ $conn = *"OK"* ]]; then

  echo -ne "Success!\nChecking results server. "; sleep 1
  rsc=$(curl -s -I --retry 5 --retry-connrefused --url $collection_server)

  if [[ $rsc = *"OK"* ]]; then
    echo -ne "Success!\nGathering system info. "; sleep 1
    #uuid
    uuid=$(sudo dmidecode | grep -i 'uuid' | awk '{print $2}' |\
      tr '[:upper:]' '[:lower:]')
    #system_hash
    system_hash=$(echo -n $psk$uuid | md5sum | awk '{print $1}')
    #cpu_model (model name)
    cpu_model=$(lscpu | grep -i 'model name' |\
      awk '{print substr($0, index($0,$3))}' | sed -e 's/ /_/g')
    #cpu_sig (stepping, model, family)
    cpu_sig=$(echo -n $(lscpu | grep -i 'stepping' | awk '{print $2}')"_"\
      $(lscpu | grep -i 'model' | grep -v 'name' | awk '{print $2}')"_"\
      $(lscpu | grep -i 'family' | awk '{print $3}'))
    #cpu_arch (architecture, sockets, cores per socket, threads per core)
    arch=$(lscpu | grep -i 'architecture' | awk '{print $2}')
    sockets=$(lscpu | grep -i 'socket(s)' | awk '{print $2}')
    cores=$(lscpu | grep -i 'core(s) per socket' | awk '{print $4}')
    threads=$(lscpu | grep -i 'thread(s) per core' | awk '{print $4}')
    cpu_arch=$(echo $arch"_"$sockets"_"$cores"_"$threads)
    #memory (used, free, total in megabytes)
    unalias free 2> /dev/null
    memory=$(free -m | grep -i 'mem'  | awk '{print $3 "_" $4 "_" $2}')
    #aes_inst
    if [ $(lscpu | grep -ci aes) -ge 1 ];\
      then aes_inst=true; else aes_inst=false; fi
    #aes_bench (in MiB/s [source review confirmed])
    aes_bench=0
    aes_bench_count=10
    echo -ne "Done!\nRunning AES benchmarks. "
    for ((loop=1;loop<=$aes_bench_count;loop++)); do
      aes_bench_next=$(cryptsetup benchmark --cipher aes |\
        grep aes | awk -F' ' '{print $5}')
      aes_bench=$(bc <<< "scale=2; $aes_bench+$aes_bench_next")
    done; sleep 2
    #divide by number of tests
    aes_bench=$(bc <<< "scale=2; $aes_bench/$aes_bench_count")

    #flops_bench setup
    echo -ne "Done!\nRunning FLOPS benchmark. "

    #size_dimensions=sqrt((free memory in bytes * 0.05) / 8)
    free_mem=$(free -b | grep -i 'mem' | awk '{print $4}')
    use_mem=$(bc <<< "scale=2; $free_mem*0.05")
    prob_size=$(bc <<< "scale=0; sqrt($use_mem/8)")

    #prepare the config file
    #reference: www.netlib.org/benchmark/hpl/tuning.html
    #           www.netlib.org/benchmark/hpl/faqs.html
    line1_2="config\nfile\n" #unused
    line3_4="HPL.out\n6\n" #output file, type
    line5_6="1\n$prob_size\n" #num prob sizes, prob size(s)
    line7_8="1\n16\n" #num block sizes, block size(s)
    line9="0\n" #process mapping (0 row-major, 1 column-major)
    line10_12="1\n$(($sockets*$threads))\n$cores\n" #num grids, P, Q
    line13="16.0\n" #residual threshold
    line14_21="1\n2\n1\n4\n1\n2\n1\n1\n" #
    line22_23="1\n1\n" #num broadcast, broadcast type [0..5]
    line24_25="1\n0\n" #num look ahead, look ahead depth [0..2]
    line26_27="2\n64\n" #swap type [0..2], swap threshold
    line28_31="0\n0\n1\n8\n"

    #combine the config lines
    config="$line1_2$line3_4$line5_6$line7_8$line9$line10_12$line13"
    config="$config$line14_21$line22_23$line24_25$line26_27$line28_31"

    #write the config file
    echo -e $config | sudo tee /etc/hpl/HPL.dat >/dev/null

    #run the benchmark
    sudo -u nobody mpirun --oversubscribe \
      -n $(($sockets*$cores*$threads)) \
      /usr/bin/xhpl-ompi > ~/HPL.out

    #get the flops value
    flops_bench=$(cat ~/HPL.out | grep -m 2  Gflops -A2 | \
      awk END{print} | awk '{print $7}')

    #results_string
    echo -ne "Done!\nSubmitting results. "
    results_string=$(echo -n "system_hash="$system_hash"&"\
      "uuid="$uuid"&device_id="$device_id"&cpu_model="$cpu_model"&"\
      "cpu_sig="$cpu_sig"&cpu_arch="$cpu_arch"&memory="$memory"&"\
      "aes_inst="$aes_inst"&aes_bench="$aes_bench"&"\
      "flops_bench="$flops_bench"&submit=Submit" | tr -d '[:space:]')
    #submit results
    if [ $(curl -s -d $results_string \
      $collection_server"/index.php" |\
      head -n1 | grep -ci 'success') -ge 1 ];\
      then echo "Success!"; else echo "Failed."
    fi
  else
    echo "Failed. Proxy or filter blocking *.amazonaws.com? Server down?"
  fi
else
  echo "Failed. Wired connection? DHCP available? Cable attached?"
fi

#goodbye
echo "Script complete!"
echo "Press Enter to Shutdown or Ctrl+C to exit to terminal."
read -s
sudo shutdown now
