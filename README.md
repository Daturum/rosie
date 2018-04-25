# Rosie
Rosie is a tool (a Rails engine) for lightning-fast prototyping and interface building.
It enables a GoogleDoc-like write-and-check development in browser with Ruby on Rails.

Name "Rosie" is made up from Roles Scenarios Interfaces: the approach to organize and
isolate work on interfaces in a large system or a rapidly developed product.

# Why?
The work of interface programmers is very difficult.
In many cases it is more complex than that of lead backend developers or even system architects.
The main reason for this is that interface programmers often need to know the whole
underlying object model and system-wide business logic of the interfaces they are working on,
even if this information is isolated by MVC or MVVM architectures.
The other reason is that interface programmers need to have all the backend development
environment locally and merge it with their favorite frontend development tools. In worst cases
interface programmers are forced to use a frontend technology that is made standard for a project
but is a total overkill or lack for the tasks they are working on.

These reasons altogether take an interface programmer days to start working on a new project.
More than that, they make interface programmer highly dependent on backend programmers and technology
which slows down the development by times.
Rosie is created to circumvent these restrictions.

# Meet Rosie: ROles and Scenarios IntErfaces
The good news is that an interface programmer actually doesn't need to have all the
backend set up and business logic learned to create the interface.
That comes from the definition of an interface: an interface is a way for a user to communicate with the system.
A user doesn't need to know how the system works to work with it. Neither does interface programmer.
Everything a user (and an interface programmer) needs to know is which objects they can work with and
how to work with them.

Let's look at our users as business roles - different roles use the system to do different tasks,
and these tasks may require different approaches to building interfaces. We need to provide high quality interfaces
for our clients, but our admins and content managers may live fine with automatically generated admin panels.
That's also the way to create tasks for interface programmers: an interface programmer gets
the knowledge what a business role need to do (what user scenarios they need to perform).
Also the interface programmer gets the list of objects to display and to modify.

# Solved tasks
- Quick start of a frontend programmer to work on a project. No backend environment setup is needed.
- Independence from backend. Frontend programmer does not need to know anything about the project's
architecture and backend technologies. The communication between frontend and backend is standardized via JSON api calls.
- Availability to have several independent interface programmers and interface technologies on a single project.
- Interface programmer does not need to learn all the business logic of the project to solve a task. The context of an interface programmer is strictly a defined user scenario of a business role. The scenarios and roles are isolated, so a change in one scenario won't affect scenarios of other roles.

# Solution
The architecture and backend development of a system stays the same. Some interfaces may also be created in a
standard manner where it is applicable (mostly when backend developers create admin panels).

When an interface programmer comes to project, they use favorite tools and environments to create interfaces (be it webpack or notepad).
Interfaces are isolated by roles and scenarios. It is possible but not recommended to use same components of interfaces in different roles.
Interface programmers integrate the interface code in a browser via fast and easy communication with backed programmers. The data format can be arbitrary but it is advised to use standard json.

That makes an interface task to be totally isolated, with the static json file as a part of a task. The integratioin into the system is the as simple as substitution of a static json by a dynamically generated one.

Debugging and development is also performed in browser.
The interface code reaches maximum maintainability as it is isolated from backed and sliced by roles and scenarios.

# Version control
Work-in-progress is stored in a database and is available for edition, run and review by special system roles.
When the work is done, the interface programmer asks the repository owner to download modifications and add them to the version control system, singed by this interface programmer. The rest of the workflow is the same as with backend development.

# File structure
Rosie adds a folder "app/interfaces" to the hosting application. The folder has this structure
- interfaces
- - role_1 (default is 'user')
- - - layout/layout.[format].[handler]
- - - layout/script.[format].[handler]
- - - layout/style.[format].[handler]
- - - scenario_1/scenario_1.[format].[handler] (default is 'start')
- - - scenario_1/controller.rb
- - - scenario_1/script.[format].[handler]
- - - scenario_1/style.[format].[handler]
- - - scenario_1/partial_1.[format].[handler]
- - - scenario_1/partial_N.[format].[handler]
- - - ...
- - - scenario_N/scenario_N.[format].[handler]
- - - ...
- - role_2
- - ...
- - public_files/

All these files are used and interpreted at the engine level.
