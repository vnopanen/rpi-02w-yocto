# Minimal Yocto MCP Server (`yocto-mcp`)

`yocto-mcp` is a lightweight Model Context Protocol (MCP) server written in C for Yocto Linux systems.

---

## 1. Yocto Integration

Add the recipe to your image build configuration (e.g. `kas-project.yml` or `local.conf`):
   ```bitbake
   IMAGE_INSTALL:append = " yocto-mcp"
   ```
---

## 2. Setting up AGY to Connect

Add the `yocto-mcp` server to AGY MCP configuration file (`~/.gemini/config/mcp_config.json`):

```json
{
  "mcpServers": {
    "rpi-yocto": {
      "command": "ssh",
      "args": [
        "root@<RPI-IP-ADDRESS>",
        "yocto-mcp"
      ]
    }
  }
}
```
---

## 3. Supported MCP Tools

| Tool Name | Parameters | Description |
| :--- | :--- | :--- |
| `get_sysinfo` | none | Returns overview of CPU load, RAM usage, kernel release, and uptime. |
| `execute_command` | `command` (string) | Executes diagnostic shell commands (e.g., `dmesg`, `free -m`, `ip a`). |
| `read_file` | `path` (string), `max_bytes` (int) | Reads content from log/config files safely. |

---

## 4. Quick Testing via Command Line

Verify stdin/stdout JSON-RPC over SSH:

```bash
# List available tools
echo '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' | ssh root@<RPI-IP-ADDRESS> yocto-mcp

# Get system info
echo '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"get_sysinfo"}}' | ssh root@<RPI-IP-ADDRESS> yocto-mcp
```
