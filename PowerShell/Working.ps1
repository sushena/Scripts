try {
    $tcpConn = New-Object System.Net.Sockets.TcpClient '127.0.0.1', 80; 
    if($tcpConn.Connected) {
		"OK"
        New-Item -path "C:\Users\sushena.p\Desktop\" -type file -name "test.txt" -ErrorAction SilentlyContinue
	}
}
Catch {
    Write-Host $_.Exception.Message
}
Finally {
    if ( Test-Path C:\Users\Vijay.annekar\Desktop\test.txt )
    {
        Write-Host " ** NO EMAIL ** " -BackgroundColor Red
        Remove-Item -Path C:\Users\sushena.p\Desktop\test.txt -ErrorAction SilentlyContinue
    }
    elseif (!( Test-Path C:\Users\sushena.p\Desktop\test.txt ))
    {
        if ( $True )
        { 
            Write-Host "Sending Email" -BackgroundColor DarkGreen
            C:\Users\Vijay.annekar\Desktop\test.txt
        }

    }
} 

    #Remove-Item -Path C:\Users\Vijay.annekar\Desktop\test.txt