# FASM-locker
Simple educational prototype of WinLocker, FASMW-x64
IMPORTANT DISCLAIMER AND WARNING

This software is created EXCLUSIVELY FOR EDUCATIONAL PURPOSES within the field of cybersecurity research and learning.

IT IS STRICTLY PROHIBITED TO USE THIS PROGRAM FOR:

    Any illegal activities

    Malicious purposes

    Locking computers without explicit owner permission

    Extortion or ransom demands

    Any form of personal gain

Using such programs for malicious purposes is punishable by law under various legal frameworks including:

    Computer Fraud and Abuse Act (CFAA) in the United States

    Article 273 of the Criminal Code of the Russian Federation (Creation, use and distribution of malicious computer programs)

    Similar computer crime legislation in other jurisdictions

    Data protection and privacy laws

The author assumes no responsibility for any illegal use of this code. This project is intended solely for academic study in controlled environments such as cybersecurity courses, penetration testing labs, or personal research on isolated systems.
PROGRAM FUNCTIONALITY

This educational WinLocker demonstrates techniques used in system locking malware for defensive cybersecurity learning purposes.

The program implements three main functionalities that are characteristic of locker-type malware:

    Autostart persistence - The program registers itself in the Windows Registry to execute automatically upon system startup, demonstrating persistence mechanisms used by malicious software.

    Keyboard blocking - Using low-level keyboard input interception techniques including MapVirtualKey functions, the program blocks keyboard input to prevent user interaction with the system.

    Secure Attention Sequence (SAS) disruption - The program disables the Ctrl-Alt-Delete combination and related security features that normally allow users to access the Windows Security screen, Task Manager, or log out.

These techniques are presented for analytical purposes to help security professionals understand how such malware operates, thereby enabling them to develop better defensive strategies, detection mechanisms, and removal tools.
INTENDED USE AND ETHICAL CONSIDERATIONS

This code should only be used in the following contexts:

    Academic cybersecurity courses with proper supervision

    Personal research on isolated, non-networked virtual machines

    Defensive security training to understand attack vectors

    Development of countermeasures and detection systems

Before using this software, ensure you have:

    Written permission from all affected system owners

    Isolated laboratory environment without network connectivity

    Proper safeguards to prevent accidental execution on production systems

    Understanding of relevant laws and regulations in your jurisdiction

TECHNICAL IMPLEMENTATION NOTES

The program demonstrates several Windows API techniques that are commonly exploited by malware. These include registry manipulation for persistence, hooking mechanisms for input control, and system policy subversion for disabling security features. Understanding these techniques is crucial for security professionals who need to analyze, detect, and remediate actual malware infections.
CONCLUSION

This educational tool serves as a resource for those studying offensive security techniques in order to build better defensive capabilities. Like any powerful tool, it can be used for both constructive and destructive purposes. The cybersecurity community depends on ethical researchers who use such knowledge to protect systems rather than compromise them.

Remember that unauthorized use of such software against systems you do not own or have explicit permission to test is illegal and unethical. Always operate within legal boundaries and adhere to ethical guidelines in cybersecurity research.
