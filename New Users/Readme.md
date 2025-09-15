Instructions to go here

# NewUserOrCopy_Template.csv

Action: N = new user, C = copy from an existing user.

OU: used only when Action is N; specify the target OU. (ex. OU=Users,OU=Company,DC=Domain,DC=com)

Domain: used only when Action is N; specify the target UPN domain. (ex. company.com) 

SourceSam: used only when Action is C; provide the existing account to copy. (ex. jdoe)

Title, Department, Manager, Phone, and Email are optional in either case.

Password must satisfy the script’s complexity rules (≥12 chars with upper‑ & lowercase, digits, and symbols).
