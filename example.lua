--[[

TaskScheduler Example
made by @knopka_01 :D

]]

local TaskScheduler = require(121440418698601)
TaskScheduler:AddLog("TaskScheduler Module Loaded", "require module")

local function Task1()
	print("Task 1 is running!")
	wait(1)
	return "Task 1 result"
end

local function Task2()
	print("Task 2 is running!")
	error("Task 2 Error! Oh no!!!") -- Simulate an error
end

local function Task3()
	print("Task 3 is running!")
	wait(2)
	return "Task 3 result"
end

local function Task4()
	print("Task 4 is running!")
	wait(3)
	return "Task 4 result"
end

local task1 = TaskScheduler:AddTask("Task1", Task1, nil, TaskScheduler.PriorityLevels.High, 5)
local task2 = TaskScheduler:AddTask("Task2", Task2, { "Task1" }, TaskScheduler.PriorityLevels.Normal, 5)
local task3 = TaskScheduler:AddTask("Task3", Task3, { "Task2" }, TaskScheduler.PriorityLevels.Low, 5)
local task4 = TaskScheduler:AddTask("Task4", Task4, nil, TaskScheduler.PriorityLevels.Normal, 10)


task1:SetCategory("NetworkTasks")
task2:SetCategory("NetworkTasks")
task3:SetNamespace("Compute")
task4:SetNamespace("Compute")

task2.MaxRetries = 3
task2.RetryStrategy = TaskScheduler.RetryStrategies.Exponential

TaskScheduler:AddThrottlingRule("NetworkThrottle", 2)
task1.ThrottleKey = "NetworkThrottle"

task1.OnStart = function(task)
	print(task.Name .. " has started")
end

task1.OnComplete = function(task)
	print(task.Name .. " completed with result: " .. tostring(task.Result))
end

task2.OnFail = function(task)
	print(task.Name .. " failed with error: " .. tostring(task.Error))
end

task2.OnRetry = function(task)
	print(task.Name .. " retrying, attempt " .. task.Retries)
end

TaskScheduler:AddTaskToGroup("ImportantTasks", task1)
TaskScheduler:AddTaskToGroup("ImportantTasks", task2)
TaskScheduler:AddTaskToGroup("ComputeTasks", task3)
TaskScheduler:AddTaskToGroup("ComputeTasks", task4)

TaskScheduler.GlobalErrorHandler = function(task)
	print("Global error handler: Task " .. task.Name .. " failed.")
end

TaskScheduler:RunGroup("ImportantTasks")

task.wait(2)
TaskScheduler:PauseTask("Task3")
print("Task 3 paused")
task.wait(3)
TaskScheduler:ResumeTask("Task3")
print("Task 3 resumed")

TaskScheduler:CancelTask("Task4")
print("Task 4 was cancelled")

TaskScheduler:RunAll()

local logs = TaskScheduler:GetLogs()
for i, log in ipairs(logs) do
	print("Log " .. i .. ": " .. log.Message .. " (Time: " .. log.Time .. ")")
end

-- Example of cancelling or pausing tasks dynamically
-- TaskScheduler:CancelTask("LoadPlayerData")
-- TaskScheduler:PauseAllTasks()
-- TaskScheduler:ResumeAllTasks()
