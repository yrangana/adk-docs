#!/bin/bash
# Copyright 2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


set -euo pipefail

PYTHON_VERSIONS=("3.10" "3.11" "3.12")
PYTHON_DIR="samples/python"

# Check for Gemini configuration. Should be removed for other LLMs.
if [ -n "${GOOGLE_GENAI_USE_VERTEXAI}" ] && { [ -n "${GOOGLE_CLOUD_PROJECT}" ] && [ -n "${GOOGLE_CLOUD_LOCATION}" ] || [ -n "${GOOGLE_API_KEY}" ]; }; then
  echo "All required variables are set."
else
  echo "One or more required variables are not set."
  exit 1
fi

# Set appropriate python version for testing
check_python_installation() {
  local python_version="$1"
  # This will likely vary depending upon the Python installation folder in your system.
  # Replace the path, by finding python installation "which python3"
  # todo: Should be dockerized.
  local python_path="/Library/Frameworks/Python.framework/Versions/$python_version/bin/"

  # Check if the specified Python version exists
  if [[ ! -d "$python_path" ]]; then
    echo "Python $python_version not found at $python_path. Skipping this version."
    return 1
  fi

  # Prepend the correct Python version to the PATH
  export PATH="$python_path:$PATH"

  # Verify the Python version
  if [[ "$(python3 --version 2>&1 | awk '{print $2}' | cut -d'.' -f1-2)" != "$python_version" ]]; then
    echo "Error: Python version mismatch. Expected $python_version, found $(python3 --version)"
    exit 1
  fi

  echo "Using Python $python_version"
}

# Retrieve only folders which contain "requirements.txt" file. Exclude .venv directory.
find_sample_dirs() {
  find $PYTHON_DIR -type d -not -path "*/.venv*" -exec test -e '{}'/requirements.txt \; -print
}

build_and_test() {
  local sample_dir="$1"
  local python_version="$2"

  # Store current directory.
  curr_dir=$(pwd)
  cd "$sample_dir"

  echo "--- Starting tests for Python $python_version and sample directory $sample_dir ---"

  # Create a virtual environment
  echo "Creating virtual environment"
  python3 -m venv .venv
  source .venv/bin/activate

  # Install pip and lint dependencies
  echo "Installing lint dependencies"
  python3 -m pip install --upgrade pip --quiet
  pip install flake8 black --quiet

  # Install code sample dependencies
  echo "Installing code sample dependencies..."
  pip install -r requirements.txt --quiet
  if [ -e requirements-test.txt ]; then
    echo "Installing code testing dependencies..."
    pip install -r requirements-test.txt --quiet
  else
    pip install pytest --quiet
  fi

  # Run black to auto-correct formatting issues.
  if ! python3 -m black . ; then
    echo "black auto-correct failed in $sample_dir"
  fi

  # Run flake8 to catch linting issues not handled by black.
  # This will be moved to a separate workflow in Github actions to not block testing.
  # todo: move the flake8 config to .flake8
  if ! python3 -m flake8 . --exclude .venv ; then
    echo "Flake8 linting failed in $sample_dir"
    exit 1 # Exit with error code
  fi
  echo "Linting completed successfully."

  # Run pytest and write output to a txt file. This will be used to show failed tests later.
  echo "Running pytest in $sample_dir ..."
  pytest

  echo "--- Tests passed for Python $python_version and sample directory $sample_dir ---"

  # cd to the original directory.
  cd "$curr_dir"
}

# ------ INVOKE ------
sample_dirs="$(find_sample_dirs)"
for python_version in "${PYTHON_VERSIONS[@]}"; do
  if check_python_installation "$python_version" -ne 0; then
    IFS=$'\n'
    for sample_dir in $sample_dirs; do
      build_and_test "$sample_dir" "$python_version"
    done
  fi
done