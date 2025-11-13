**Team Ascott IoT / Hardware Security Assessment**
Course: COSC 6840 
Student: Alyssa Scott
Project: Final Project “The Node” Assessment
Client: AVENGERS Manufacturing, Inc.

Project Overview
This repository contains all work for the IoT and Hardware Security Assessment Final Project.

Our client, AVENGERS Manufacturing, requested a security analysis of their new IoT device, “The Node.” The device collects sensitive data in an industrial environment and will be deployed at scale, meaning attackers may have physical access.

The goal of this assessment is to evaluate the security of both the microcontroller and flash memory, identify weaknesses, and extract five required flags:

UART Flag
Password Cracking Flag
Internal MCU Flash Flag
External SPI Flash Flag
Secret Stream Flag
All flags are in the format:
FLAG{SECRET_VALUE_HERE}

The project includes interacting with hardware interfaces, dumping memory, cracking hashes, and collecting data streams exposed by the device.

Assessment Targets
Device Components
Microcontroller: STM32F103C8T6
External SPI Flash: Winbond W25Q64JV
Relevant Interfaces
USART2 @ 9600 baud — Hidden debug shell
SWD (Serial Wire Debug) — Internal flash memory
SPI — External flash extraction
Additional streaming interface — For secret data stream flag
Repository Structure Team_Ascott/ 
├── IOT.py 
├── README.md 
├── extracted/  
├── screenshots/ 
├── report/ 
├── Slides/ 
├── Requirements/ 


Tools Used Hardware Tools: 
• FT232RL USB-to-Serial Adapter (UART) 
• ST-Link v2 Programmer (SWD) 
• CH341a or Bus Pirate (SPI Flash) 
• Jumper wires • Debug headers on The Node device

Software Tools: 
• screen / minicom 
• OpenOCD 
• flashrom 
• xxd, grep, binwalk 
• hashcat, John the Ripper, CrackStation 
• Python 3.x

Running the Script Example usage: python3 fw_triage.py --port /dev/ttyUSB0 --baud 9600

Findings Summary Detailed results and flag values will be documented in findings.md.

Final Deliverables 
• Final Report: report/final.pdf 
• Slide Deck: slides/deck.pdf 
• Evidence Screenshots: screenshots/
