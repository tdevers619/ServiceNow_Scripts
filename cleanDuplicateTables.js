// Define a GlideRecord object to query the incident table
var grIncident = new GlideRecord('incident');

// Query to retrieve all incidents, ordering by short_description
grIncident.orderBy('short_description');
grIncident.query();

var previousShortDescription = '';
var previousSysId = '';
var duplicateCount = 0;

while (grIncident.next()) {
    var currentShortDescription = grIncident.short_description.toString();

    // Check if the current incident's short_description matches the previous one
    if (currentShortDescription === previousShortDescription) {
        // Duplicate detected, delete the current record
        gs.log('Deleting duplicate incident: ' + grIncident.number);
        grIncident.deleteRecord();
        duplicateCount++;
    } else {
        // Update the previous variables to the current record's data
        previousShortDescription = currentShortDescription;
        previousSysId = grIncident.sys_id.toString();
    }
}

// Log the number of duplicates deleted
gs.log('Total duplicates deleted: ' + duplicateCount);
