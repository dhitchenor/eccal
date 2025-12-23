/==============================================\
## TRANSLATIONS
\==============================================/
- [Translating for EcCal](#translating-for-eccal)
- [Translation System Usage Examples](#translation-system-usage-examples)


## TRANSLATING FOR ECCAL
========================

Located within assets/i18n, are the language specific json files;
these files are used by the translation system, to provide specific string translations throughout the app.

#### Points to note:
- spaces after various punctuation marks are hardcoded, and don't need to be present in the translation itself
    - if this causes can issue for a specific language, please file an issue on github, and we can discuss it
- curly braces, are not punctuation marks, and should be kept in the translation (see below)
    - example: {1}
    - another example: \"{0}\"

### Translating, with examples

#### Standard Translation:
- Straightforward, possibly contextual, word for word translation
- example:
    - "refresh": "Refresh"

#### Translation with placeholder
- retain the curly braces, as they appear, as it is a placeholder for a variable that the code will insert during translation
- there may be more than one placeholder in a translation string; please be aware
- the positioning of the curly braces will depend on the grammatical requirements of the language

- "error": "Error: {0}"
    - (EXAMPLE) Returns 'Error: network unavailable'
  
#### Translation with existing punctuation
- While some punctuation marks, may be relevant in English, they may not be relevant in another language
    - the following punctuation marks (see example, below) denote theat the users attention will be required shortly, in the future
    - if this is usually be conveyed in a different way in the relevant language, it should be reflected in the translation
- example
    - "syncing": "Syncing..."


## TRANSLATION SYSTEM USAGE EXAMPLES 
====================================
- intended for developers, not translators

#### Method 1: Without placeholders
Text('save'.tr())
Text('moods.happy'.tr())

- 'save'.tr()
    - Returns "Save"
- 'moods.happy'.tr()
    - Returns "Happy"

#### Method 2: With static information for placeholders
Text('error_saving'.tr(['Network error']))
Text('location_added'.tr(['37.7749, -122.4194']))

- 'error_saving'.tr(['Network error'])
    - Returns "Error saving: Network error"
- 'location_added'.tr(['37.7749, -122.4194'])
    -Returns "Location added: 37.7749, -122.4194"

#### Method 3: With variables for placeholders
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('delete_dialog.title'.tr()),
    content: Text('delete_dialog.message'.tr([entryTitle])),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text('cancel'.tr()),
      ),
      TextButton(
        onPressed: () => _deleteEntry(),
        child: Text('delete'.tr()),
      ),
    ],
  ),
);

- 'delete_dialog.title'.tr()
    - is the same as Method 1
- 'delete_dialog.message'.tr([entryTitle])
    - Returns the 'Delete Dialog' message, with the Title of the entry, placed where the {0}, is located (see the translation files)

#### Method 4: With time specific placeholders
DropdownMenuItem(value: 60, child: Text(formatDuration(1, 'hr'))),
DropdownMenuItem(value: 120, child: Text(formatDuration(2, 'hr'))),

- formatDuration(1, 'hr')
    - Returns '1 hr'
- formatDuration(2, 'hr')
    - Returns '2 hrs'


### FURTHER EXAMPLES OF TRANSLATING EXISTING CODE:

#### Ensuring strings are used:
- converting potentially unknown values/variables to string, may result in less errors.
    - Before:
        SnackBar(content: Text('Error saving: $e'))

    - After (converts error value to string):
        SnackBar(content: Text('save_dialog.error_saving'.tr([e.toString()])))