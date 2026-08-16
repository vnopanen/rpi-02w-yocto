#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/sysinfo.h>
#include <sys/utsname.h>

#define BUFFER_SIZE 65536
#define MAX_OUTPUT 32768

static void print_json_escaped(const char *str) {
    if (!str) return;
    for (size_t i = 0; str[i] != '\0'; i++) {
        switch (str[i]) {
            case '"':  fputs("\\\"", stdout); break;
            case '\\': fputs("\\\\", stdout); break;
            case '\b': fputs("\\b", stdout); break;
            case '\f': fputs("\\f", stdout); break;
            case '\n': fputs("\\n", stdout); break;
            case '\r': fputs("\\r", stdout); break;
            case '\t': fputs("\\t", stdout); break;
            default:
                if ((unsigned char)str[i] < 32) {
                    printf("\\u%04x", (unsigned char)str[i]);
                } else {
                    fputc(str[i], stdout);
                }
                break;
        }
    }
}

static void send_response(const char *id, const char *result_json) {
    printf("{\"jsonrpc\":\"2.0\",");
    if (id) {
        printf("\"id\":%s,", id);
    } else {
        printf("\"id\":null,");
    }
    printf("\"result\":%s}\n", result_json);
    fflush(stdout);
}

static void send_error(const char *id, int code, const char *message) {
    printf("{\"jsonrpc\":\"2.0\",");
    if (id) {
        printf("\"id\":%s,", id);
    } else {
        printf("\"id\":null,");
    }
    printf("\"error\":{\"code\":%d,\"message\":\"", code);
    print_json_escaped(message);
    printf("\"}}\n");
    fflush(stdout);
}

static void handle_initialize(const char *id) {
    const char *result = "{"
        "\"protocolVersion\":\"2024-11-05\","
        "\"capabilities\":{\"tools\":{}},"
        "\"serverInfo\":{\"name\":\"yocto-mcp\",\"version\":\"1.0.0\"}"
    "}";
    send_response(id, result);
}

static void handle_tools_list(const char *id) {
    const char *result = "{"
        "\"tools\":["
            "{"
                "\"name\":\"execute_command\","
                "\"description\":\"Execute a diagnostic shell command on the Raspberry Pi Yocto system.\","
                "\"inputSchema\":{"
                    "\"type\":\"object\","
                    "\"properties\":{"
                        "\"command\":{\"type\":\"string\",\"description\":\"Shell command to execute (e.g. dmesg, free -m, ip a)\"}"
                    "},"
                    "\"required\":[\"command\"]"
                "}"
            "},"
            "{"
                "\"name\":\"get_sysinfo\","
                "\"description\":\"Get quick diagnostic system info (kernel, CPU load, RAM usage, uptime).\","
                "\"inputSchema\":{"
                    "\"type\":\"object\","
                    "\"properties\":{}"
                "}"
            "},"
            "{"
                "\"name\":\"read_file\","
                "\"description\":\"Read contents of a log or config file on the target Yocto system.\","
                "\"inputSchema\":{"
                    "\"type\":\"object\","
                    "\"properties\":{"
                        "\"path\":{\"type\":\"string\",\"description\":\"Absolute path to file\"},"
                        "\"max_bytes\":{\"type\":\"integer\",\"description\":\"Max bytes to read (default 4096)\"}"
                    "},"
                    "\"required\":[\"path\"]"
                "}"
            "}"
        "]"
    "}";
    send_response(id, result);
}

static void handle_execute_command(const char *id, const char *cmd) {
    if (!cmd || strlen(cmd) == 0) {
        send_error(id, -32602, "Invalid params: command is required");
        return;
    }

    FILE *fp = popen(cmd, "r");
    if (!fp) {
        send_error(id, -32000, "Failed to execute command");
        return;
    }

    char *output_buf = malloc(MAX_OUTPUT);
    if (!output_buf) {
        pclose(fp);
        send_error(id, -32000, "Out of memory");
        return;
    }

    size_t bytes_read = fread(output_buf, 1, MAX_OUTPUT - 1, fp);
    output_buf[bytes_read] = '\0';
    pclose(fp);

    printf("{\"jsonrpc\":\"2.0\",\"id\":%s,\"result\":{\"content\":[{\"type\":\"text\",\"text\":\"", id ? id : "null");
    print_json_escaped(output_buf);
    printf("\"}]}}\n");
    fflush(stdout);

    free(output_buf);
}

static void handle_get_sysinfo(const char *id) {
    struct sysinfo info;
    struct utsname uts;
    
    sysinfo(&info);
    uname(&uts);

    char buf[1024];
    snprintf(buf, sizeof(buf),
        "Sysname: %s\\nNodename: %s\\nRelease: %s\\nVersion: %s\\nMachine: %s\\n"
        "Uptime: %ld seconds\\nLoad 1m: %.2f, 5m: %.2f, 15m: %.2f\\n"
        "Total RAM: %lu MB, Free RAM: %lu MB, Shared RAM: %lu MB, Buffer RAM: %lu MB\\n"
        "Processes: %d",
        uts.sysname, uts.nodename, uts.release, uts.version, uts.machine,
        info.uptime,
        info.loads[0] / 65536.0, info.loads[1] / 65536.0, info.loads[2] / 65536.0,
        (info.totalram * info.mem_unit) / (1024 * 1024),
        (info.freeram * info.mem_unit) / (1024 * 1024),
        (info.sharedram * info.mem_unit) / (1024 * 1024),
        (info.bufferram * info.mem_unit) / (1024 * 1024),
        info.procs
    );

    printf("{\"jsonrpc\":\"2.0\",\"id\":%s,\"result\":{\"content\":[{\"type\":\"text\",\"text\":\"%s\"}]}}\n", id ? id : "null", buf);
    fflush(stdout);
}

static void handle_read_file(const char *id, const char *path, int max_bytes) {
    if (!path || strlen(path) == 0) {
        send_error(id, -32602, "Invalid params: path is required");
        return;
    }
    if (max_bytes <= 0 || max_bytes > MAX_OUTPUT) {
        max_bytes = 4096;
    }

    FILE *fp = fopen(path, "r");
    if (!fp) {
        send_error(id, -32000, "Could not open file");
        return;
    }

    char *buf = malloc(max_bytes + 1);
    if (!buf) {
        fclose(fp);
        send_error(id, -32000, "Out of memory");
        return;
    }

    size_t n = fread(buf, 1, max_bytes, fp);
    buf[n] = '\0';
    fclose(fp);

    printf("{\"jsonrpc\":\"2.0\",\"id\":%s,\"result\":{\"content\":[{\"type\":\"text\",\"text\":\"", id ? id : "null");
    print_json_escaped(buf);
    printf("\"}]}}\n");
    fflush(stdout);

    free(buf);
}

static char* extract_json_field(const char *json, const char *field) {
    char search_pattern[128];
    snprintf(search_pattern, sizeof(search_pattern), "\"%s\":", field);
    char *pos = strstr(json, search_pattern);
    if (!pos) return NULL;
    
    pos += strlen(search_pattern);
    while (*pos == ' ' || *pos == '\t') pos++;
    
    if (*pos == '"') {
        pos++;
        char *end = strchr(pos, '"');
        if (!end) return NULL;
        size_t len = end - pos;
        char *res = malloc(len + 1);
        strncpy(res, pos, len);
        res[len] = '\0';
        return res;
    } else {
        char *end = pos;
        while (*end && *end != ',' && *end != '}' && *end != ']' && *end != ' ' && *end != '\n' && *end != '\r') end++;
        size_t len = end - pos;
        char *res = malloc(len + 1);
        strncpy(res, pos, len);
        res[len] = '\0';
        return res;
    }
}

static void process_line(char *line) {
    if (strlen(line) == 0) return;

    char *id = extract_json_field(line, "id");
    char *method = extract_json_field(line, "method");

    if (!method) {
        // Might be a notification or response
        if (id) free(id);
        return;
    }

    if (strcmp(method, "initialize") == 0) {
        handle_initialize(id);
    } else if (strcmp(method, "notifications/initialized") == 0) {
        // Notification, no response required
    } else if (strcmp(method, "tools/list") == 0) {
        handle_tools_list(id);
    } else if (strcmp(method, "tools/call") == 0) {
        char *params_pos = strstr(line, "\"params\":");
        char *name = NULL;
        char *cmd = NULL;
        char *path = NULL;
        if (params_pos) {
            name = extract_json_field(params_pos, "name");
            cmd = extract_json_field(params_pos, "command");
            path = extract_json_field(params_pos, "path");
        }

        if (name) {
            if (strcmp(name, "execute_command") == 0) {
                handle_execute_command(id, cmd);
            } else if (strcmp(name, "get_sysinfo") == 0) {
                handle_get_sysinfo(id);
            } else if (strcmp(name, "read_file") == 0) {
                handle_read_file(id, path, 4096);
            } else {
                send_error(id, -32601, "Unknown tool name");
            }
            free(name);
        } else {
            send_error(id, -32602, "Missing tool name in params");
        }

        if (cmd) free(cmd);
        if (path) free(path);
    } else {
        send_error(id, -32601, "Method not found");
    }

    if (id) free(id);
    if (method) free(method);
}

int main(void) {
    char *line = malloc(BUFFER_SIZE);
    if (!line) return 1;

    while (fgets(line, BUFFER_SIZE, stdin) != NULL) {
        // Strip trailing newline/carriage return
        size_t len = strlen(line);
        while (len > 0 && (line[len-1] == '\n' || line[len-1] == '\r')) {
            line[--len] = '\0';
        }
        process_line(line);
    }

    free(line);
    return 0;
}
