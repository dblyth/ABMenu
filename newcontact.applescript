-- newcontact.applescript
-- ABMenu3

--  Created by David Blyth on 6/28/08.
--  Copyright 2008 David Blyth. All rights reserved.

tell application "Address Book"
	activate
	set the_id to (get id of (make new person))
	save addressbook
end tell

tell application "Finder"
	set the_url to "addressbook://" & the_id & "?edit"
	open location the_url
end tell