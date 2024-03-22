#!/bin/bash
service autofs restart
	
cd /usr/sap/NW1/SYS/

ln -s /sapmnt/NW1/global global
ln -s /sapmnt/NW1/profile profile
crm resource cleanup
