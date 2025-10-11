import os
import subprocess
import shutil
import json

#Hardcoded list of firmware files
firmware_files = ["firmware/bare-metal-demo.elf", "firmware/dcs-8000lh.bin", "firmware/wr-841n.bin"]

#Store results for all firmware files
all_results = [] 

#Function to run Nosey Parker on an ELF file and return findings
def run_nosey_parker(target_path, firmware_name):
    np_ds = f"nosey_datastore_{os.path.basename(firmware_name).replace('.', '_')}"
    #NP executable
    np_exe = "/home/linuxbrew/.linuxbrew/bin/noseyparker"
    #Temp file for Nosey Parker output
    temp_file = "temp_nosey_output.json"

    #Remove existing datastore if present, to make script idempotent
    try:
        if os.path.exists(np_ds):
            shutil.rmtree(np_ds)
        
        print("Running nosey parker...")
        subprocess.run([np_exe, "scan", "--datastore", np_ds, target_path],
                       capture_output=True, text=True)
        
        # Generate report to temporary file
        subprocess.run([np_exe, "report", "--datastore", np_ds, "--format", "json", "-o", temp_file],
                       capture_output=True, text=True)

        # Read the findings
        with open(temp_file, "r") as f:
            elf_findings = json.load(f)
        
        # Remove temp file
        if os.path.exists(temp_file):
            os.remove(temp_file)
        
        if os.path.exists(np_ds):
            shutil.rmtree(np_ds)

        return elf_findings
            
    except Exception as e:
        print(f"Error: {e}")
        return []

# Create directories
os.makedirs("extracted", exist_ok=True)
os.makedirs("report", exist_ok=True)

# Extract .bin files with binwalk
for file in firmware_files:
    if file.endswith('.bin'):
        print(f"Extracting {file}...")
        output_folder = "extracted/extracted_" + os.path.basename(file)
        result = subprocess.run(["binwalk", "-e", file, "-C", output_folder], 
                               capture_output=True, text=True)
        
        bin_findings = []
        if os.path.exists(output_folder):
            squash_path = None
            for root, dirs, files_in_dir in os.walk(output_folder):
                if "squashfs-root" in dirs:
                    squash_path = os.path.join(root, "squashfs-root")
                    bin_findings.append(f"Extracted filesystem to: {squash_path}")
                    break
            
            if not squash_path:
                bin_findings.append(f"Extracted to {output_folder} (no squashfs filesystem found)")
        else:
            bin_findings.append(f"No extractable content found")

        all_results.append({
            "firmware": file,
            "type": "bin",
            "findings": bin_findings
        })

# Scan .elf files with Nosey Parker
for file in firmware_files:
    if file.endswith('.elf'):
        elf_findings = run_nosey_parker(file, file)
        all_results.append({
            "firmware": file,
            "type": "elf",
            "findings": elf_findings
        })

# Save combined results to findings.json with pretty-print
with open("report/findings.json", "w") as f:
    json.dump(all_results, f, indent=2)

print(f"All findings: report/findings.json")
print(f".Bin Saved to: extracted/")