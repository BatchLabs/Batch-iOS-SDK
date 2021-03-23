# Bridgy

Bridgy allows you to automatically generate Swift bridging headers by scanning folders on disk.
This allows your developers to freely add and remove Objective-C headers without having to manually change the bridging headers.

A good use case for this are bridging headers used in unit tests.

Bridgy allows you to generate separate headers to increase readability and cleaner git diffs.

## Usage

```
bridgy <path to config file.json>
```

## Configuration

Example configuration file:

```
// Unless absolute, all paths are relative to the configuration json you provide to the bridgy CLI
{
    "output_directory": "tests/Bridging Headers/", // Directory where the bridging headers will be generated
    "base_search_path": "source/", // Base path for "path" keys in the "header" object. Kinda works like a "base header search path"
    "headers": {
        "Login-Bridging.h": { // Output bridging header filename
            "path": "Login", // Path of the folder to scan
            "recursive": true, // Recursively scan
            "ignoredNames": "^Public.*" // Headers will be ignored if they match this regexp, use null if you want to skip anything
        }
    }
}
```

All keys are mandatory.

Note: By design, Bridgy will not follow symlinks, nor work with symlinked header files.

## Usage as a library

Bridgy can also be used as a SPM library:  

- Bridgy.Generator allows you to interact with the header generator directly
- Bridgy.CommandLine allows you to use Bridgy's CLI directly. Note that for now, this directly parses the cli arguments: feel free to copy that code in your own CLI argument parser if you need to tweak it.
