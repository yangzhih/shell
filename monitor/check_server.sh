#!/bin/sh
Resettem=$(tput sgr0)
Check_Nginx_Server()
{
	Status_code=`curl -m 5 -s -w %{http_code} http://192.168.233.129 -o /dev/null`
	if [ $Status_code -eq 000 -o $Status_code -ge 500 ];then
		echo -e '\e[32m' "Check http server error!Response status code is" $Resettem $Status_code
	else
		Http_content=$(curl -s ${Nginxserver})
		echo -e '\e[32m' "Check http server ok!\n" $Resettem $Http_content
	fi
}

Check_Mysql_Server()
{
	nc -z -w2 
}

Check_Nginx_Server
