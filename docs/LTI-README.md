# SylSpace LTI Integration for Canvas

This allows SylSpace equizzes to be embedded in Canvas assignments with automatic grade passback.

## Setup

### 1. Server Configuration

```bash
# Create LTI directories
mkdir -p /var/sylspace/lti/equizzes
mkdir -p /var/sylspace/lti/links

# Create config file
cat > /var/sylspace/lti/config.yml << 'EOF'
consumers:
  sylspace_canvas:
    secret: "YOUR_SECRET_HERE"
EOF

# Generate a secure secret
openssl rand -base64 32
# Copy output to config.yml

# Copy your equiz files
cp /path/to/your/*.equiz /var/sylspace/lti/equizzes/
```

### 2. Canvas Configuration (Admin)

1. Go to Canvas Admin → Developer Keys → + Developer Key → + LTI Key
   - Or: Course Settings → Apps → + App → Manual Entry

2. Configure the External Tool:
   ```
   Name: SylSpace Equizzes
   Consumer Key: sylspace_canvas  (must match config.yml)
   Shared Secret: YOUR_SECRET_HERE (must match config.yml)
   Launch URL: https://syllabus.space/lti/launch
   Privacy: Public (to receive student email)
   ```

3. For LTI 1.1 XML configuration (alternative):
   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <cartridge_basiclti_link xmlns="http://www.imsglobal.org/xsd/imslticc_v1p0">
     <blti:title>SylSpace Equizzes</blti:title>
     <blti:launch_url>https://syllabus.space/lti/launch</blti:launch_url>
     <blti:extensions platform="canvas.instructure.com">
       <lticm:property name="privacy_level">public</lticm:property>
       <lticm:property name="domain">syllabus.space</lticm:property>
     </blti:extensions>
   </cartridge_basiclti_link>
   ```

### 3. Adding Equizzes to Canvas Assignments

1. In Canvas, create/edit an Assignment
2. Set Submission Type to "External Tool"
3. Click "Find" and select "SylSpace Equizzes"
4. Save the assignment
5. As instructor, click the assignment - you'll see the equiz selector
6. Choose which equiz to assign
7. Students clicking the assignment will take the quiz

## How It Works

```
INSTRUCTOR FLOW:
Canvas Assignment → LTI Launch → Instructor sees equiz selector → Saves mapping

STUDENT FLOW:
Canvas Assignment → LTI Launch → Equiz renders → Student submits 
                                                      ↓
                                              Grade calculated
                                                      ↓
                                              Grade sent to Canvas
                                                      ↓
                                              Results displayed
```

## File Structure

```
/var/sylspace/lti/
├── config.yml              # Consumer credentials
├── equizzes/               # .equiz files available to assign
│   ├── quiz1.equiz
│   └── quiz2.equiz
└── links/                  # Auto-created: maps Canvas assignments to equizzes
    └── {resource_link_id}.json
```

## Grade Passback

Grades are automatically sent to Canvas when:
- The assignment is created as a graded assignment in Canvas
- Canvas provides `lis_outcome_service_url` in the LTI launch
- The student completes and submits the quiz

Grades appear in Canvas gradebook as percentage (score/total questions).

## Troubleshooting

**"Invalid LTI signature"**
- Check consumer_key matches between Canvas and config.yml
- Check secret matches exactly (no extra spaces)

**"Quiz Not Yet Available" for students**
- Instructor needs to launch the assignment first and select an equiz

**Grades not appearing in Canvas**
- Ensure assignment is set as "graded" in Canvas
- Check server logs: `/var/sylspace/log/production.log`
- Canvas needs Privacy Level set to "Public" to send outcome URLs

## Security Notes

- LTI 1.1 uses OAuth 1.0 HMAC-SHA1 signatures
- Secrets should be 32+ random characters
- Each Canvas instance should have its own consumer key/secret
