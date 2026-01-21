# SylSpace

Course management software on syllabus.space

**Live Server:** [https://auth.syllabus.space](https://auth.syllabus.space)

## Features

- **Course Management**: Create and manage multiple courses with separate instructor/student views
- **Equizzes**: Randomized quizzes with automatic grading and unlimited retakes
- **File Distribution**: Share course materials, collect homework submissions
- **Grade Center**: Track and export student grades
- **Messaging**: In-app communication between instructors and students
- **LTI 1.1 Integration**: Embed in Canvas and other LMS platforms with grade passback
- **Multiple Authentication**: OAuth (Google, Facebook), Passkeys (WebAuthn), and local authentication

## Installation

Due to the outdated three-year-old 5.18.2 version of perl still
running on MacOS, we do not recommend it. If you need to install
syllabus.space on osx, first learn brew and install a newer perl.

### Basic Steps:

These steps are for a plain ubuntu server. (The non-apt steps are
applicable everywhere, though)

* `$ sudo apt install git cpanminus make gcc libssl-dev carton`

  ```
    to download, you need git.  to install mojolicious, you
    need cpanminus, make, and gcc. we use carton to manage
    dependencies
  ```

* `$ mkdir mysylspacedir ; cd mysylspacedir`

  ```
    in this example, mysylspacedir is the directory in which
    the webapp will be installed.  you can change this to anything you
    like.  because all of sylspace will be cloned into its own
    subdirectory, you could even omit this step altogether.
  ```

* `$ git clone https://github.com/iwelch/sylspace ; cd sylspace`

  you now should have a lot of files in the mysylspacedir/sylspace directory, which you can inspect with `$ ls`.

* `carton install`

  ```
    this instructs perl to install all the cpan modules that
    sylspace needs.  make sure that there are no errors in this step.
    if there are, you will suffer endless pain later on.  warning:
    this step may take 10 minutes.

    This makes a local environment where the expected versions
    of the cpan modules used are installed, regardless of other
    things you've installed. In order to run scripts in this
    project, prefix them with `carton exec`, or add `local/lib/perl5`
    to your PERL5LIB environment variable. (for more info, see
    `perldoc Carton`)
  ```

* `carton exec perl initsylspace.pl -f`

  ```
    this builds the basic storage hierarchy in the
    filesystem located at $ENV{SYLSPACE_PATH} (/var/sylspace/ by default)
    such as $ENV{SYLSPACE_PATH}/courses, $ENV{SYLSPACE_PATH}/users,
    $ENV{SYLSPACE_PATH}/templates/, etc.
  ```

* `carton exec perl bin/load_site startersite`

  ```
    this builds a nice starter site for test purposes.  for
    example, it creates a corpfin website (in
    /var/sylspace/courses/corpfin/) that the webapp will recognize as
    a corporate finance website.
  ```

* `sudo updatedb`

  ```
    runserver.pl uses `locate sylspace/SylSpace` to detect where it is installed, so it needs you to run updatedb at least once.
  ```

* `carton exec perl SylSpace daemon`

  ```
    Starts the server in development mode. For production, use hypnotoad.
  ```

now open your browser and point it to `http://lvh.me`. when you
are done, click back on your terminal window and ^C out.

### Real Operation

Real operation means a system that works (for now only) on
http://*.syllabus.space and that has Google etc. authentication of
remote Internet users enabled.

To enable remote authentication, create a file containing the
proper set of secrets that the Google, Facebook, and Paypal
Authentications need. This can be a headache. The
`SylSpace-Secrets.template` file tries to give some guidance. You
need a file

```
SylSpace-Secrets.conf
```

which contains your private authentication secrets (for oauth,
google, paypal, gmail, etc).

Again, the contents of the SylSpace-Secrets.conf file are
illustrated in `SylSpace-Secrets.template`. You can edit and
rename the template!

The app won't work without at least one OAuth provider configured.
In addition, you must set the site_name so that cookies can work
as expected across subdomains.

If you see an error

```
   Warning: 'message must be a string at (eval 253) line 63
```

it probably means that your login credentials for email sending are
off.

## LTI 1.1 Integration (Canvas, etc.)

SylSpace supports LTI 1.1 for integration with Learning Management Systems like Canvas. See [docs/LTI-README.md](docs/LTI-README.md) for detailed setup instructions.

### Quick Canvas Setup

1. In Canvas, go to **Settings → Apps → +App**
2. Select **Configuration Type: By URL** or **Manual Entry**
3. Configure with:
   - **Consumer Key**: Your LTI consumer key (from SylSpace-Secrets.conf)
   - **Shared Secret**: Your LTI shared secret
   - **Launch URL**: `https://COURSE.syllabus.space/lti` (replace COURSE with your course subdomain)

### Grade Passback

SylSpace automatically sends grades back to Canvas when:
- Students complete equizzes
- The LTI launch included grade passback parameters (lis_outcome_service_url)

### Configuration

Add to your `SylSpace-Secrets.conf`:

```perl
lti => {
    consumer_key => 'your-key-here',
    consumer_secret => 'your-secret-here',
},
```

## Passkey Authentication (WebAuthn)

SylSpace supports passwordless authentication via passkeys:

1. Users register a passkey from their profile settings
2. On subsequent logins, they can authenticate with fingerprint, Face ID, or security key
3. Passkeys are tied to the user's email address

Passkey data is stored in `/var/sylspace/passkeys/`.

## Automatic (Re-) Start

We provide a systemd service file that you can use for running a
production server. Look at the files in the `systemd` folder, and
edit them to include the locations of your paths, and then copy
them over to one of your systems systemd directories
(`/lib/systemd/system` or `/etc/systemd/system`), the run
`systemctl daemon-reload`, then `systemctl start SylSpace`. You
can also run `systemctl enable SylSpace` to have it always turn on
on startup.

## Developing

SylSpace is written in perl with the Mojolicious web framework.

The `SylSpace` top-level executable initializes a variety of global features and then starts the app loop.

Each webpage ("controller") sits in its own `Controller/*.pm` file, which you can deduce by looking at the URL in the browser.

Almost every controller uses functionality that is in the model,
which is in `Model/*.pm`.

The equiz evaluator is completely separate and laid out into `Model/eqbackend`.

All equizzes that come with the system are in `templates/equiz/`

## File Itinerary

### The Top Level

* **initsylspace.pl** : initializes the `/var/sylspace` hierarchy
* **initsylspace.pm** : module for initialization
* **SylSpace** : The Main Executable
* **SylBackup** : Backup utility
* cpanfile : describes all required perl modules
* cpanfile.snapshot : locked versions
* SylSpace-Secrets.template : template for secrets config
* start-hypnotoad.sh, stop-hypnotoad.sh, restart-hypnotoad.sh : server control scripts
* redirector : HTTP to HTTPS redirector
* README.md : this file

### ./docs

* LTI-README.md : LTI integration documentation

### ./lib/SylSpace/Controller: The URLs

Each file corresponds to a URL. Typically, `AuthGoclass` → `/auth/goclass`.

**Authentication:**
* Aboutus.pm
* AuthAuthenticator.pm - Main login page with OAuth options
* AuthBioform.pm, AuthBiosave.pm - User profile
* AuthGoclass.pm - Class selection
* AuthIndex.pm
* AuthInstructorinfo.pm
* AuthLocalverify.pm - Local/test authentication
* AuthMagic.pm - Magic link login
* AuthPasskey.pm - Passkey/WebAuthn authentication
* AuthSendmail.pm
* AuthSettimeout.pm
* AuthTestsetuser.pm
* AuthUserdisroll.pm
* AuthUserenrollform.pm, AuthUserenrollsave.pm
* Login.pm, Logout.pm
* Privacy.pm

**LTI:**
* LTI.pm - LTI 1.1 launch and grade passback

**Student:**
* StudentAnswerdelete.pm
* StudentEquizcenter.pm
* StudentFaq.pm
* StudentFilecenter.pm, StudentFileview.pm, StudentOwnfileview.pm
* StudentGradecenter.pm
* StudentHwcenter.pm
* StudentIndex.pm
* StudentMsgcenter.pm
* StudentQuickinfo.pm
* StudentStudent2instructor.pm

**Instructor:**
* InstructorCiobuttonsave.pm, InstructorCioform.pm, InstructorCiosave.pm
* InstructorCollectstudentanswers.pm
* InstructorCptemplate.pm
* InstructorDesign.pm
* InstructorDownload.pm, InstructorSilentdownload.pm
* InstructorEdit.pm, InstructorEditsave.pm
* InstructorEquizcenter.pm, InstructorEquizmore.pm
* InstructorFaq.pm
* InstructorFilecenter.pm, InstructorFiledelete.pm, InstructorFilemore.pm, InstructorFilesetdue.pm
* InstructorGradecenter.pm, InstructorGradedownload.pm, InstructorGradeform.pm
* InstructorGradesave.pm, InstructorGradesave1.pm, InstructorGradetaskadd.pm
* InstructorHwcenter.pm, InstructorHwmore.pm
* InstructorIndex.pm
* InstructorInstructor2student.pm, InstructorInstructoradd.pm, InstructorInstructordel.pm, InstructorInstructorlist.pm
* InstructorMsgcenter.pm, InstructorMsgdelete.pm, InstructorMsgsave.pm
* InstructorRmtemplates.pm
* InstructorSitebackup.pm
* InstructorStudentdetailedlist.pm
* InstructorUserenroll.pm
* InstructorView.pm

**Core/Shared:**
* Enter.pm
* Equizcenter.pm, Equizgrade.pm, Equizrate.pm, Equizrender.pm
* Faq.pm
* Filecenter.pm
* Hwcenter.pm
* Index.pm
* Msgcenter.pm, Msgmarkasread.pm
* PaypalHandler.pm
* Showseclog.pm, Showtweets.pm
* Testquestion.pm
* Uploadform.pm, Uploadsave.pm

### ./bin: support scripts

* addsite.pl : CLI to add a new site with instructor
* load_site : deploys a site layout based on configuration files in share/fixtures

### ./share/fixtures: site layouts

Testing fixtures that can be deployed for testing:

* startersite.yml : setup of a corpfin course with 2 users
* messysite.yml : setup of four different courses and many users

### ./lib/SylSpace/Model: The Workhorse

* Controller.pm : HTML-output utility routines
* Model.pm : core model functions (user management, sitebackup, bio, messages, equiz interface)
* Files.pm : storing and retrieving homeworks, equizzes, and files
* Grades.pm : storing and retrieving grades
* Utils.pm : common routines (globbing, file reading, etc.)
* Webcourse.pm : creating and removing courses
* csettings-schema.yml : course settings schema
* usettings-schema.yml : user settings schema

### ./lib/SylSpace/Model/eqbackend:

* eqbackend.pl : the main quiz evaluation program
* EvalOneQuestion.pm
* EvalStudentAnswers.pm
* ParseTemplate.pm
* RenderEquiz.pm

### ./templates/layouts:

* sylspace.html.ep : the main template
* auth.html.ep
* both.html.ep
* instructor.html.ep
* student.html.ep

### ./templates/equiz : Quizzes

#### ./templates/equiz/tutorials:
* 1simple.equiz
* 2medium.equiz
* 3advanced.equiz

#### ./templates/equiz/starters:
* blackscholes.equiz
* finance.equiz
* headerinfo.equiz
* math.equiz
* message.equiz
* multchoice.equiz
* plain.equiz
* statistics.equiz
* various.eqz

#### ./templates/equiz/options:
* 232andrei01.equiz through 232andrei06.equiz

## License

AGPL-3.0
