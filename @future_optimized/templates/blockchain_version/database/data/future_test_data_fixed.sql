-- Future版测试数据SQL脚本 (修复版)
-- 生成时间: 2025-10-06T11:12:19.570363

INSERT INTO users (username, email, password_hash, first_name, last_name, role, status, email_verified, phone_verified, created_at) VALUES
('admin', 'admin@jobfirst.com', 'hashed_admin_password', 'Admin', 'User', 'admin', 'active', 1, 1, '2024-10-06 11:12:19'),
('frank_miller_1', 'frank_miller_1@example.com', 'hashed_password_1', 'Frank', 'Miller', 'user', 'active', 1, 0, '2024-12-03 11:12:19'),
('charlie_smith_2', 'charlie_smith_2@example.com', 'hashed_password_2', 'Charlie', 'Smith', 'user', 'inactive', 0, 0, '2025-06-29 11:12:19'),
('henry_rodriguez_3', 'henry_rodriguez_3@example.com', 'hashed_password_3', 'Henry', 'Rodriguez', 'user', 'active', 0, 1, '2025-07-02 11:12:19'),
('bob_smith_4', 'bob_smith_4@example.com', 'hashed_password_4', 'Bob', 'Smith', 'user', 'active', 1, 0, '2024-10-31 11:12:19'),
('alice_johnson_5', 'alice_johnson_5@example.com', 'hashed_password_5', 'Alice', 'Johnson', 'user', 'active', 1, 1, '2025-07-01 11:12:19'),
('henry_miller_6', 'henry_miller_6@example.com', 'hashed_password_6', 'Henry', 'Miller', 'user', 'active', 1, 0, '2025-06-29 11:12:19'),
('bob_martinez_7', 'bob_martinez_7@example.com', 'hashed_password_7', 'Bob', 'Martinez', 'user', 'inactive', 0, 1, '2025-08-01 11:12:19'),
('henry_williams_8', 'henry_williams_8@example.com', 'hashed_password_8', 'Henry', 'Williams', 'user', 'inactive', 1, 0, '2025-04-19 11:12:19'),
('diana_martinez_9', 'diana_martinez_9@example.com', 'hashed_password_9', 'Diana', 'Martinez', 'user', 'active', 0, 1, '2025-01-09 11:12:19');
