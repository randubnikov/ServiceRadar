CREATE TABLE IF NOT EXISTS services (
    id         INT AUTO_INCREMENT PRIMARY KEY,
    name       VARCHAR(100) NOT NULL,
    url        VARCHAR(500) NOT NULL,
    dev_name   VARCHAR(100) NOT NULL,
    dev_email  VARCHAR(150) NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS incidents (
    id            INT AUTO_INCREMENT PRIMARY KEY,
    service_id    INT NOT NULL,
    status        VARCHAR(20)  NOT NULL,
    error_message VARCHAR(500),
    created_at    DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (service_id) REFERENCES services(id)
);
