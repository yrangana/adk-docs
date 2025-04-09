# Installing ADK

## Create & activate virtual environment (Recommended)

We recommend using a virtual environment such as [venv](https://docs.python.org/3/library/venv.html).

```bash
# Create
python -m venv .venv
# Activate (each new terminal)
# macOS/Linux: source .venv/bin/activate
# Windows CMD: .venv\Scripts\activate.bat
# Windows PowerShell: .venv\Scripts\Activate.ps1
```

### Install ADK

```bash
pip install google-adk
```

(Optional) Verify your installation:

```bash
pip show google-adk
```

## Next steps

* Try creating your first agent with the [**Quickstart**](quickstart.md)
