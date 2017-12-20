1.命令行输入./run.sh或双击run.sh选择“在终端执行”
1.1 3.按照提示输入BMC IP触发远程日志收集；不输入IP直接回车会触发本地OS日志收集；
或
2.命令行执行./DiagInfoCollect bmcip bmcusername bmcpassword  -- 远程收集
        执行./DiagInfoCollect  -- 本地收集

3.日志收集完成后会在同级目录下产生ip_time.tar.gz或sn_time.tar.gz的压缩包即为收集的日志文件；
