# SylSpace
Course management software on syllabus.space


## Installation

Due to the outdated three-year-old 5.18.2 version of perl still
running on MacOS, we do not recommend it.  If you need to install
syllabus.space on osx, first learn brew and install a newer perl.

### Basic Steps:

These steps are for a plain ubuntu server. (The non-apt steps are
applicable everywhere, though)

* `$ sudo apt install git cpanminus make gcc libssl-dev carton`

        to download, you need git.  to install mojolicious, you
        need cpanminus, make, and gcc. we use carton to manage
        dependencies

* `$ mkdir mysylspacedir ; cd mysylspacedir`

        in this example, mysylspacedir is the directory in which
        the webapp will be installed.  you can change this to anything you
        like.  because all of sylspace will be cloned into its own
        subdirectory, you could even omit this step altogether.

* `$ git clone https://github.com/iwelch/sylspace ; cd sylspace`

	you now should have a lot of files in the mysylspacedir/sylspace directory, which you can inspect with `$ ls`.

* `carton install`

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

* `carton exec perl initsylspace.pl -f`

        this builds the basic storage hierarchy in the
        filesystem located at $ENV{SYLSPACE_PATH} (/var/sylspace/ by default)
        such as $ENV{SYLSPACE_PATH}/courses, $ENV{SYLSPACE_PATH}/users,
        $ENV{SYLSPACE_PATH}/templates/, etc.

* `carton exec perl bin/load_site startersite`
	
        this builds a nice starter site for test purposes.  for
        example, it creates a corpfin website (in
        /var/sylspace/courses/corpfin/) that the webapp will recognize as
        a corporate finance website.

* `sudo updatedb`

        runserver.pl uses `locate sylspace/SylSpace` to detect where it is installed, so it needs you to run updatedb at least once.

- `carton exec perl runserver.pl`

        runserver.pl is smart enough to figure out whether it
        is running on http://*.syllabus.space domain (where it should use
        hypnotoad) or on another computer (where there is only local test
        user authentication and the tester wants to see what URLs are
        being requested on the terminal).


now open your  browser and point it to `http://lvh.me`.  when you
are done, click back on your terminal window and ^C out of
runserver.pl.

If you aren't comfortable letting sylspace play around with your
filesystem, then you can still test by using the included docker
image. Make sure that docker is installed, and then build the
image by running `docker build -t sylspace:dev .` while in the
projects directory.

After the image is finished building, you can run it with the
included `run_docker` script. You can pass in any command to have
it run in the container.


### Real Operation

Real operation means a system that works (for now only) on
http://*.syllabus.space and that has Google etc. authentication of
remote Internet users enabled.

To enable remote authentication, create a file containing the
proper set of secrets that the Google, Facebook, and Paypal
Authentications need.  This can be a headache.  The
`SylSpace-Secrets.template` file tries to give some guidance.  You
need a file

	SylSpace-Secrets.conf

which contains your private authentication secrets (for oauth,
google, paypal, gmail, etc).

Again, the contents of the SylSpace-Secrets.conf file are
illustrated in `SylSpace-Secrets.template`.  You can edit and
rename the template!

The app won't work without at least one OAuth provider configured.
In addition, you must set the site_name so that cookies can work
as expected across subdomains.

If you see an error

       Warning: 'message must be a string at (eval 253) line 63

it probably means that your login credentials for email sending are
off.

## Running from the docker container

TODO- coming soon...


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

All default quizzes that course instructors can copy into their own home directories are in `templates/equiz/` .




## File Itinerary

### The Top Level

* **initsylspace.pl**
:	the most important file.  initializes the `/var/sylspace` hierarchy

* **SylSpace**
:	The Main Executable

* runserver.pl
:	smartly starts the server, depending on the hostname, with hypnotoad or morbo


The rest are also useful.

* cpanfile
:	describes all required perl modules.  Used only once during installation as `carton install`


* SylSpace-Secrets.conf@
:	A symlink to outside the hierarchy to keep secrets

* SylSpace-Secrets.template
:	Illustrates how the secret file should look like

* SylSpace.service
:	The systemd service file, to be copied into /lib/systemd/system/ for automatic (re-)start

* start-hypnotoad.sh
:	just a link to runserver.pl

* stop-hypnotoad.sh
:	reminder how to stop hypnotoad

* FUTURE.md
:	plans

* README.md
:	this file


### ./lib/SylSpace: Testing tools

* Test.pm - testing helpers. See `perldoc ./lib/SylSpace/Test.pm` for more info
* Test/App.pm - an object to load the App into Test2::MojoX, with
  some special helper functions
* Test/Utils.pm - shared testing functions (not toooooo heavily used... yet)


### ./lib/SylSpace/Controller: The URLs

Each file corresponds to a URL.  Typically, a file such as `AuthGoclass` (note capitalization) is `/auth/goclass`.

* Aboutus.pm
* AuthAuthenticator.pm
* AuthBioform.pm
* AuthBiosave.pm
* AuthGoclass.pm
* AuthIndex.pm
* AuthLocalverify.pm
* AuthMagic.pm
* AuthSendmail.pm
* AuthSettimeout.pm
* AuthTestsetuser.pm
* AuthUserdisroll.pm
* AuthUserenrollform.pm
* AuthUserenrollsave.pm
* Enter.pm
* Equizcenter.pm
* Equizgrade.pm
* Equizrate.pm
* Equizrender.pm
* Faq.pm
* Filecenter.pm
* Hwcenter.pm
* Index.pm
* InstructorCiobuttonsave.pm
* InstructorCioform.pm
* InstructorCiosave.pm
* InstructorCollectstudentanswers.pm
* InstructorCptemplate.pm
* InstructorDesign.pm
* InstructorDownload.pm
* InstructorEdit.pm
* InstructorEditsave.pm
* InstructorEquizcenter.pm
* InstructorEquizmore.pm
* InstructorFaq.pm
* InstructorFilecenter.pm
* InstructorFiledelete.pm
* InstructorFilemore.pm
* InstructorFilesetdue.pm
* InstructorGradecenter.pm
* InstructorGradedownload.pm
* InstructorGradeform.pm
* InstructorGradesave.pm
* InstructorGradesave1.pm
* InstructorGradetaskadd.pm
* InstructorHwcenter.pm
* InstructorHwmore.pm
* InstructorIndex.pm
* InstructorInstructor2student.pm
* InstructorInstructoradd.pm
* InstructorInstructordel.pm
* InstructorInstructorlist.pm
* InstructorMsgcenter.pm
* InstructorMsgdelete.pm
* InstructorMsgsave.pm
* InstructorRmtemplates.pm
* InstructorSilentdownload.pm
* InstructorSitebackup.pm
* InstructorStudentdetailedlist.pm
* InstructorUserenroll.pm
* InstructorView.pm
* Login.pm
* Logout.pm
* Msgcenter.pm
* Msgmarkasread.pm
* PaypalHandler.pm
* Showseclog.pm
* Showtweets.pm
* StudentEquizcenter.pm
* StudentFaq.pm
* StudentFilecenter.pm
* StudentFileview.pm
* StudentGradecenter.pm
* StudentHwcenter.pm
* StudentIndex.pm
* StudentMsgcenter.pm
* StudentOwnfileview.pm
* StudentQuickinfo.pm
* StudentStudent2instructor.pm
* Testquestion.pm
* Testquestion.pm.save
* Uploadform.pm
* Uploadsave.pm


### ./bin: support scripts
* addsite.pl  : CLI to add a new site with instructor
* load_site : deploys a site layout based on configuration files in share/fixtures

### ./share/fixtures: site layouts
These are testing fixtures that are used in the test suite, and
also can be deployed on your live version of the app for live
testing purposes.

The format is basically self explanatory YAML (once you know what
fields are expected by SylSpace)

* startersite.yml : contains the setup of a corpfin course with 2 users
* messysite.yml : contains a setup of four different courses and many users

### ./lib/SylSpace/Model:  The Workhorse.

* Controller.pm : all html-output related utility routines that are used many times over.
* Model.pm : many of the main model functions, excepting Files, and Grades. For example, user management, sitebackup, bio, messages, tweeting, equiz interface
* Files.pm : storing and retrieving homeworks, equizzes, and files
* Grades.pm : storing and retrieving grades
* Utils.pm : many common routines (e.g., globbing, file reading, etc.)
* Webcourse.pm : creating and removing a new course, used in addsite.pl

* csettings-schema.yml  : what course information is required and what it must satisfy
* usettings-schema.yml  : what biographical information is required and what it must satisfy


### ./lib/SylSpace/Model/eqbackend:

* eqbackend.pl*  :  the main quiz evaluation program.
  - solo = feed question from stdin
  - syntax = check an equiz

* EvalOneQuestion.pm
* EvalStudentAnswers.pm
* ParseTemplate.pm
* RenderEquiz.pm

this directory also contains some example equizzes for quicker testing

* 1simple.equiz
* tester.equiz
* testsolo.equiz



### Static Files

#### ./public/css , ./public/html , ./public/images , ./public/js

primarily lots of decorative image files, and some other browser support files.

 
#### ./public/html/ifaq:
* syllabus-sophisticated.html
* syllabus-sophisticated.png
* syllabus.html
 


### ./templates/layouts:

* sylspace.html.ep : the key look of the website.  other ep files inherit it, and only change it a little
* auth.html.ep
* both.html.ep@
* instructor.html.ep
* student.html.ep

 
### ./templates/equiz : Quizzes


#### ./templates/equiz/tutorials:

* 1simple.equiz
* 2medium.equiz
* 3advanced.equiz
* 4final-mba-2015.equiz  --- needs checking


#### ./templates/equiz/starters:

* blackscholes.equiz
* bs-sample-answer.png
* bs-sample-render.png
* finance.equiz
* headerinfo.equiz
* math.equiz
* message.equiz
* multchoice.equiz
* plain.equiz
* statistics.equiz
* various.eqz


#### ./templates/equiz/corpfinintro:

* 02a-tvm.equiz
* 02b-tvm.equiz
* 03-perpann.equiz
* 04a-capbudgrules.equiz
* 04b-capbudgrules.equiz
* 05a-yieldcurve.equiz
* 05b-yieldcurve.equiz
* 06a-uncertainty.equiz
* 06b-uncertainty.equiz
* 07-invintro.equiz
* 08-invest.equiz
* 09-benchmarking.equiz
* 10-capm.equiz
* 11-imperfect.equiz
* 12-effmkts.equiz
* 13-npvapplications.equiz
* 14-valuation.equiz
* 15-comparables.equiz
* 16-capstruct-intro.equiz
* 17-capstruct-more.equiz

the following were for playing around:

* eqformat.pl
* final-mba-2015.equiuiz --- needs fixing
* guidelines.txt


#### ./templates/equiz/options:

* 232andrei01.equiz
* 232andrei02.equiz
* 232andrei03.equiz
* 232andrei04.equiz
* 232andrei05.equiz
* 232andrei06.equiz

