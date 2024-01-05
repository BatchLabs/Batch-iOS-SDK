#
# https://github.com/ChrisMash/PublicAPIMonitoringExample
#
# Generates the ObjC API from the specified ObjCnframework and places it in the specified directory
# with the filename <FRAMEWORK_NAME>_objc_api.txt
#
# NOTE: Should be run with bash rather than sh due to usage of echo -e.
#
# Parameters:
# - The name of the framework file (with extension)
# - The path to the framework file
# - The directory/Users/arnaud.r/Sources/temps/PublicAPIMonitoringExample/Scripts/gen_objc_api_from_objc_framework.sh to output the file to
#
# Example: bash gen_objc_api_from_objc_framework.sh ObjC_Framework.framework ./ ./api
#

#
# Will echo out the first subdirectory found that contains a .framework in it,
# under the specified search path
# Example: findFirstFrameworkSubDirectory "folder1/folder2"
#
findFirstFrameworkSubDirectory() {
    SEARCH_PATH=$1
    for ENTRY in "${SEARCH_PATH}"/*; do
      for SUB_ENTRY in "${ENTRY}"/*; do
        if [[ $SUB_ENTRY == *.framework ]]; then
            echo $SUB_ENTRY
            return 0
        fi
      done
    done
    
    exit 1
}

#
# Will echo out the first subdirectory found that contains a .framework in it,
# with the specified subdirectory, under the specified search path
# Example: findFirstFrameworkFolder "Headers" "folder1/folder2"
#
findFirstFrameworkFolder() {
    DESIRED_SUBDIR=$1
    SEARCH_DIR=$2

    if [[ $SEARCH_DIR == *.xcframework* ]]; then
        # .xcframeworks contain multiple .framework folders, each with a Headers folder
        echo "$(findFirstFrameworkSubDirectory $SEARCH_DIR)/${DESIRED_SUBDIR}"
    elif [[ $SEARCH_DIR == *.framework* ]]; then
        # .frameworks have the Headers folder directly inside
        echo "${SEARCH_DIR}/${DESIRED_SUBDIR}"
    else
        echo "Error: Expected to be looking in a .framework or .xcframework"
        exit 1
    fi
    
    return 0
}

STARTTIME=$(date +%s)
FRAMEWORK_NAME_WEXT=$1
FRAMEWORK_DIR=$2
OUTPUT_DIR=$3

# Strip off the extension to get the framework name
FRAMEWORK_NAME="${FRAMEWORK_NAME_WEXT%.*}"
# Generate the path to the framework header
HEADERS_PATH=$(findFirstFrameworkFolder "Headers" "${FRAMEWORK_DIR}/${FRAMEWORK_NAME_WEXT}")
FW_HEADER_PATH="${HEADERS_PATH}/${FRAMEWORK_NAME}.h"

API=""
IN_COMMENT_BLOCK=false
SCANNED_HEADERS=()

scanHeader() {
    HEADER_PATH=$1
    # If we've not scanned this header yet
    if ! [[ " ${SCANNED_HEADERS[@]} " =~ " ${HEADER_PATH} " ]]; then
        #echo "Scanning: ${HEADER_PATH}"
        SCANNED_HEADERS+=($HEADER_PATH)
        
        addToAPI $HEADER_PATH
        scanChildHeaders $HEADER_PATH
#    else
#        echo "Skipping (already scanned): ${HEADER_PATH}"
    fi
}

SL_COMMENT_PATTERN="//*"
ML_COMMENT_START_PATTERN="\/\**"
ML_COMMENT_END_PATTERN="\*\/*"

isNotCommentLine() {
    [[ $1 != $SL_COMMENT_PATTERN
    && $1 != $ML_COMMENT_START_PATTERN
    && $1 != $ML_COMMENT_END_PATTERN ]]
    return
}

addToAPI() {
    HEADER_PATH=$1
    HEADER=$(cat ${HEADER_PATH})

    # Add relevant lines to the API
    while IFS= read -r line; do
        # Trim any whitespace
        TRIMMED_LINE=$(echo "${line}" | tr -d '[:space:]')
        # If it's length is greater than 0
        if [ ${#TRIMMED_LINE} -gt 0 ]; then
            # If it isn't a comment
            if isNotCommentLine "${TRIMMED_LINE}"; then
                # If we're not in a multi-line comment block
                if ! $IN_COMMENT_BLOCK; then
                    # If it isn't a NS_ (don't care about these, e.g. NS_ASSUME_NONNULL_BEGIN)
                    if [[ $TRIMMED_LINE != NS_* ]]; then
                        # If it isn't a #<something> (e.g. #import, #include etc.)
                        if [[ $TRIMMED_LINE != \#* ]]; then
                            # If it isn't a @<something>; (e.g. forward declaration such as @class X; or @protocol Y;. Or a @import)
                            if [[ $TRIMMED_LINE != @class*\;
                            && $TRIMMED_LINE != @protocol*\;
                            && $TRIMMED_LINE != @import*\; ]]; then
                                # Add it to the API
                                API="${API}\n${line}"
#                            else
#                                echo "Skipped @;: ${line}"
                            fi
#                       else
#                           echo "Skipped #: ${line}"
                        fi
#                   else
#                       echo "Skipped NS_: ${line}"
                    fi
#                else
#                       echo "Skipped comment: ${line}"
                fi
            else
                #echo "Skipped comment: ${line}"
                # Skipped a comment, check if we're in a multi-line comment block or not
                if [[ $TRIMMED_LINE != $SL_COMMENT_PATTERN
                && $TRIMMED_LINE == $ML_COMMENT_START_PATTERN ]]; then
                    IN_COMMENT_BLOCK=true
                elif [[ $TRIMMED_LINE == $ML_COMMENT_END_PATTERN ]]; then
                    IN_COMMENT_BLOCK=false
                fi
            fi
        fi
    done <<< "$HEADER"
}

scanChildHeaders() {
    HEADER_PATH=$1
    # Find all the lines that import/include another header
    IMPORTS=$(grep "^#\(import\|include\).*$" ${HEADER_PATH})
    #echo "Imports:\n${IMPORTS}"
    # If we found any imports (length of string greater than 0)
    if [ ${#IMPORTS} -gt 0 ]; then
        # For each one
        while IFS= read -r line; do
            # Remove the '#import " prefix (or include)
            LINE_WITHOUT_PREFIX=${line#"#import "}
            LINE_WITHOUT_PREFIX=${LINE_WITHOUT_PREFIX#"#include "}
            # Determine whether it's angle brackets or quotations around the header path
            if [[ $LINE_WITHOUT_PREFIX == \<* ]]; then
                # Skip over irrelevant imports that aren't for the framework in questions
                if [[ $LINE_WITHOUT_PREFIX != "<${FRAMEWORK_NAME}"* ]]; then
                    continue
                fi
                # Remove the '<framework_name/' prefix
                CHILD_HEADER=${LINE_WITHOUT_PREFIX#<${FRAMEWORK_NAME}\/}
                # Remove the '>' suffix
                CHILD_HEADER=${CHILD_HEADER%>}
            else
                # Remove the '"' prefix
                CHILD_HEADER=${LINE_WITHOUT_PREFIX#\"}
                # Remove the '"' suffix
                CHILD_HEADER=${CHILD_HEADER%\"}
            fi
            # Generate the path to the header
            CHILD_HEADER_PATH="${HEADERS_PATH}/${CHILD_HEADER}"
            # Scan it
            scanHeader $CHILD_HEADER_PATH
        done <<< "$IMPORTS"
    fi
}

# Scan the framework header and the headers it includes
scanHeader ${FW_HEADER_PATH}
# Output the public API to a file
echo -e "${API}" > "${OUTPUT_DIR}/${FRAMEWORK_NAME}_objc_api.txt"

ENDTIME=$(date +%s)
echo "Executed in ~$(($ENDTIME - $STARTTIME))s"
