# Team Ascott — IoT / Hardware Security Assessment  
**Course:** COSC 6840 
**Student:** Alyssa Scott  
**Project:** Final Project “The Node” Assessment  
**Client:** AVENGERS Manufacturing, Inc.

---

## Project Overview

This repository contains all work for the **IoT and Hardware Security Assessment Final Project**.

Our client, AVENGERS Manufacturing, requested a security analysis of their new IoT device, “The Node.” The device collects sensitive data in an industrial environment and will be deployed at scale, meaning attackers may have physical access.

The goal of this assessment is to evaluate the security of both the microcontroller and flash memory, identify weaknesses, and extract five required flags:

1. **UART Flag**  
2. **Password Cracking Flag**  
3. **Internal MCU Flash Flag**  
4. **External SPI Flash Flag**  
5. **Secret Stream Flag**

All flags are in the format:  
`FLAG{SECRET_VALUE_HERE}`

The project includes interacting with hardware interfaces, dumping memory, cracking hashes, and collecting data streams exposed by the device.

---

## Assessment Targets

### **Device Components**
- **Microcontroller:** STM32F103C8T6  
- **External SPI Flash:** Winbond W25Q64JV  

### **Relevant Interfaces**
- **USART2 @ 9600 baud** — Hidden debug shell  
- **SWD (Serial Wire Debug)** — Internal flash memory  
- **SPI** — External flash extraction  
- **Additional streaming interface** — For secret data stream flag  

---

## 📁 Repository Structure

This repo follows the required template:


