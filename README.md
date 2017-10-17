# SylSpace
course management software on syllabus.space


## Installation

Due to the outdated three-year-old 5.18.2 version of perl still running on MacOS, we do not recommend it.  If you need to install syllabus.space on osx, first learn brew and install a newer perl first.

### Basic Steps:

These steps are for a plain ubuntu server.

* `$ sudo apt install git cpanminus make gcc`

	to download, you need git.  to install mojolicious, you need cpanminus, make, and gcc.

* `$ mkdir mysylspacedir ; cd mysylspacedir`

	in this example, mysylspacedir is the directory in which we install our webapp.  you can change this to anything you like.
	because all of sylspace will sit in its own directory, you could even omit this step altogether.

* `$ git clone https://github.com/iwelch/sylspace ; cd sylspace`

	you now should have a lot of files in the sylspace directory, which you can `$ ls`

* `$ sudo bash`

	we have to do a lot of steps as superuser, so we may as well fire up a shell to execute the many commands below:

	- `# cpanm --installdeps .`

	  this instructs perl to install all the cpan modules that sylspace needs.  make sure that there are no errors
	  in this step.  if there are, you will suffer endless pain later on.  warning: this step may take 10 minutes.

	- `# echo "127.0.0.1 syllabus.test corpfin.syllabus.test corpfin.test.syllabus.test syllabus.test.syllabus.test auth.syllabus.test" >> /etc/hosts`

	  what we really would like to do is to tell the computer that '*.syllabus.test' is not on the internet, but on localhost.  alas, the standard unix name resolver is too stupid to allow this.  A better way to accomplish this is to use a local name resolver like dnsmasq, but the installation of this is more complex.

	- `# perl initsylspace.pl -f`

	  this builds the basic storage hierarchy in /var/, such as /var/courses, /var/users, etc.

	- `# cd Model; perl mkstartersite.pl ; cd ..`
	
	  this builds a nice starter site for test purposes.  for example, it creates a corpfin website (in /var/courses/corpfin/) that the webapp will recognize as a corporate finance website.

	- `# updatedb`

	  we want runserver.pl to be able to locate 'sylspace/SylSpace`, whereever you may have installed it.  runserver.pl uses the unix utility `locate`, which depends on you having run updatedb at least once.

	- `# chown -R yourusername .`

	  this makes it easy to edit sylspace programs without having to be su.

	- `# perl runserver.pl`

	   runserver.pl is smart enough to figure out whether it is running on syllabus.space domain (where it should use hypnotoad) or on another computer (where there is only local test user authentication and the tester wants to see what URLs are being requested on the terminal).



now point your firefox (not chrome!) browser to `http://syllabus.test`.  when you are done, go back to the terminal and ^C out of runserver.pl .


### Real Operation

Real operation means a system that works (for now only) on syllabus.space and that has Google etc. authentication of remote Internet users enabled.  For testing and experimentation purposes, you almost surely do not want this.

To enable remote authentication, create a file containing the proper set of secrets that the Google, Facebook, and Paypal Authentications need.  This can be a headeach.  The `SylSpace-Secrets.template` file tries to give some guidance.  You need a file

	<somewhere-else-outside-the-git-tree>/SylSpace-Secrets.conf

which contains your private authentication secrets (for oauth, google, paypal, gmail, etc).  Next, you need to link this into the correct spot:

    # ln -s <somewhere-else-outside-the-git-tree>/SylSpace-Secrets.conf <absolute mysylspacedir>/sylspace/SylSpace-Secrets.conf

Again, the contents of the SylSpace-Secrets.conf file are illustrated in SylSpace-Secrets.template .  You can edit and rename the template!  Once installed and one you make a few changes in runserver.pl and SylSpace (which assume that you want to run production on hostname syllabus-space and testing on all other hosts), you should see working google/github/facebook login buttons and the email authentication alternative.


## Automatic (Re-) Start

For automatic start on boot and restart on crash in the real production hypnotoad on syllabus.space, do

    # cp SylSpace.service /lib/systemd/system/
    # systemctl start SylSpace


## Developing

SylSpace is written in perl Mojolicious.

The `SylSpace` top-level executable initializes a variety of global features and then starts the app loop.

Each webpage ("controller") sits in its own `Controller/*.pm` file, which you can deduce by looking at the URL in the browser.

Almost every controller uses functionality that is in the model, which is in `Model/*.pm`.  (The directory also contains some course initialization programs, such as `mkinstructor.pl` or `mksite.pl`.)

The quiz evaluator is completely separate and laid out into `Model/eqbackend`.

All default quizzes that course instructors can copy into their own home directories are in `templates/equiz/` .





## File Itinerary

### The Top Level

* **initsylspace.pl**
:	the most important file.  initializes the `/var` hierarchy

* cpanfile
:	describes all required perl modules.  Use as `cpanm --installdeps .` in this directory.  (cpanlist just lists them.)


* **SylSpace**
:	The Main Executable

* runserver.pl*
:	smartly starts the server, depending on the hostname, with hypnotoad or morbo


The rest are also useful.

* SylSpace-Secrets.conf@
:	A symlink to outside the hierarchy to keep secrets

* SylSpace-Secrets.template
:	Illustrating how the secret file should look like

* SylSpace.service
:	The systemd service file, to be copied into /lib/systemd/system/ for automatic (re-)start

* SylSpace.t*
:	Beginning to learn how to write GUI tests.  Not working

* hosts
:	a variety of hostnames used in the startersite and messysite

* nginx-config
:	untested config file for nginx.  on my server, I deinstall all other webservers and just run hypnotoad

* start-hypnotoad.sh@
:	link to runserver.pl

* stop-hypnotoad.sh*
:	reminder how to stop hypnotoad

* FUTURE.md
:	plans

* README.md
:	this file



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


fixupcamel.pl* was used to complain about misnamings inconsistenties.  mkurl.pl was used to generate a skeleton for a new url.



### ./lib/SylSpace/Model:  The Workhorse.

* **mkstartersite.t** : usually first program invoked after initsylspace.pl

* Controller.pm : all html drawing
* Model.pm : the main model functions
* Files.pm : storing and retrieving homeworks, equizzes, and files
* Files.t
* Grades.pm : storing and retrieving grades
* Grades.t
* Utils.pm : many common routines (e.g., globbing, file reading, etc.)
* Utils.t
* Webcourse.pm : creating and removing a new course, used in addsite.pl
* addsite.pl  : CLI to add a new site with instructor
* mkmessysite.t : for playing with functionality.  more extensive than mkstartersite.t

* csettings-schema.yml  : what course information is required and what it must satisfy
* usettings-schema.yml  : what biographical information is required and what it must satisfy

* V4.pm : various scribblings for the next version


### ./lib/SylSpace/Model/eqbackend:

* eqbackend.pl*  :  the main quiz evaluation program.
  - solo = feed question from stdin
  - syntax = check an equiz

* EvalOneQuestion.pm
* EvalStudentAnswers.pm
* ParseTemplate.pm
* RenderEquiz.pm

this directory contains some example equizzes here for testing

* 1simple.equiz
* tester.equiz
* testsolo.equiz



### Static Files

#### ./public/css:

* dropzone.css
* eqbackend-i.css
* eqbackend.css
* equiz.css
* fontshadow.css
* input.css
* sylspace.css
* tablesorter.css
 

#### ./public/html:

* android-icon-144x144.png
* android-icon-192x192.png
* android-icon-36x36.png
* android-icon-48x48.png
* android-icon-72x72.png
* android-icon-96x96.png
* apple-icon-114x114.png
* apple-icon-120x120.png
* apple-icon-144x144.png
* apple-icon-152x152.png
* apple-icon-180x180.png
* apple-icon-57x57.png
* apple-icon-60x60.png
* apple-icon-72x72.png
* apple-icon-76x76.png
* apple-icon-precomposed.png
* apple-icon.png
* browserconfig.xml
* eqsample02a.html
* eqsample02a.txt
* faq.html
* favicon-16x16.png
* favicon-32x32.png
* favicon-96x96.png
* favicon-uni.zip
* favicon.ico
* favicon.png
* favicons.html
* ifaq/
* instructor-syllabus.png
* manifest.json
* ms-icon-144x144.png
* ms-icon-150x150.png
* ms-icon-310x310.png
* ms-icon-70x70.png
* student-syllabus.png
* takequiz.png
* textarea.html
 
#### ./public/html/ifaq:
* syllabus-sophisticated.html
* syllabus-sophisticated.png
* syllabus.html
 

#### ./public/images:
* bullseye.png
* equiz-avatars.zip
* mickey.png
 
#### ./public/js:

* confirm.js
* dropzone.js
* eqbackend.js


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
* 4final-mba-2015.equiz


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
* eqformat.pl
* final-mba-2015.equiuiz
* guidelines.txt
* unclean/
* x@


#### ./templates/equiz/options:

* 232andrei01.equiz
* 232andrei02.equiz
* 232andrei03.equiz
* 232andrei04.equiz
* 232andrei05.equiz
* 232andrei06.equiz

