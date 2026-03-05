#include "vendor/httplib.h"
#include "vendor/json.hpp"
#include <iostream>
#include <chrono>
#include <iomanip>
#include <sstream>

std::string currentUtcTime() {
    auto now = std::chrono::system_clock::now();
    std::time_t t = std::chrono::system_clock::to_time_t(now);
    std::ostringstream oss;
    oss << std::put_time(std::gmtime(&t), "%Y-%m-%dT%H:%M:%SZ");
    return oss.str();
}

int main() {
    httplib::Server svr;

    svr.set_logger([](const httplib::Request& req, const httplib::Response&) {
        std::cout << req.method << " " << req.path
                  << " from " << req.remote_addr << std::endl;
    });

    svr.Get("/health", [](const httplib::Request& req, httplib::Response& res) {
        if (req.get_header_value("X-Debug") == "fail") {
            res.status = 500;
            res.set_content("forced failure", "text/plain");
            return;
        }
        res.status = 200;
        res.set_content("ok", "text/plain");
    });

    svr.Get("/api/time", [](const httplib::Request& req, httplib::Response& res) {
        if (req.get_header_value("X-Debug") == "fail") {
            res.status = 500;
            res.set_content("forced failure", "text/plain");
            return;
        }
        nlohmann::json body;
        body["time"] = currentUtcTime();
        res.status = 200;
        res.set_content(body.dump(), "application/json");
    });

    std::cout << "Server starting on :8080" << std::endl;
    svr.listen("0.0.0.0", 8080);
}