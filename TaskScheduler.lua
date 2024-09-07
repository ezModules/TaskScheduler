--[[
              // TaskScheduler Module \\
// Effortless Task Management, Infinite Possibilities \\
  
by @knopka_01 :D
]]

local TaskScheduler = {}

TaskScheduler.Tasks = {}
TaskScheduler.RunningTasks = {}
TaskScheduler.MaxConcurrentTasks = 5
TaskScheduler.CurrentConcurrentTasks = 0
TaskScheduler.PriorityLevels = { Low = 1, Normal = 2, High = 3 }
TaskScheduler.TaskGroups = {}
TaskScheduler.GlobalErrorHandler = nil
TaskScheduler.Logs = {}
TaskScheduler.ThrottlingRules = {}
TaskScheduler.RetryStrategies = { Linear = "linear", Exponential = "exponential", Jitter = "jitter" }
TaskScheduler.RateLimits = {}
TaskScheduler.Metrics = { TotalTasks = 0, CompletedTasks = 0, FailedTasks = 0, TotalRunTime = 0 }
TaskScheduler.ExecutionModes = { Parallel = "parallel", Sequential = "sequential" }

TaskScheduler.TaskQueue = {}
TaskScheduler.TaskCategories = {}
TaskScheduler.TaskNamespace = {}
TaskScheduler.MonitoringHooks = {}
TaskScheduler.MaxRetriesGlobal = 5

local Task = {}
Task.__index = Task

function Task.new(name, func, dependencies, priority, timeout, metadata)
	return setmetatable({
		Name = name,
		Func = func,
		Dependencies = dependencies or {},
		Status = "queued",
		Result = nil,
		Error = nil,
		Retries = 0,
		MaxRetries = 3,
		RetryDelay = 1,
		Priority = priority or TaskScheduler.PriorityLevels.Normal,
		Timeout = timeout or 10,
		Progress = 0,
		StartTime = nil,
		EndTime = nil,
		OnStart = nil,
		OnComplete = nil,
		OnFail = nil,
		OnRetry = nil,
		Metadata = metadata or {},
		Log = {},
		RetryStrategy = TaskScheduler.RetryStrategies.Linear,
		ThrottleKey = nil,
		TaskType = "basic",
		Category = nil,
		Namespace = nil
	}, Task)
end

function Task:SetCategory(category)
	self.Category = category
	TaskScheduler:AddTaskToCategory(category, self)
end

function Task:SetNamespace(namespace)
	self.Namespace = namespace
	TaskScheduler:AddTaskToNamespace(namespace, self)
end

function Task:SetProgress(percentage)
	self.Progress = percentage
	TaskScheduler:AddLog(self.Name .. " progress: " .. self.Progress .. "%", self.Name)
end

function Task:Run()
	if self.Status ~= "queued" then return end
	self.Status = "running"
	self.StartTime = tick()

	if self.OnStart then
		self.OnStart(self)
	end

	TaskScheduler:HandleThrottling(self)

	local success, result = pcall(self.Func)

	self.EndTime = tick()
	if success then
		self.Status = "completed"
		self.Result = result
		TaskScheduler.Metrics.CompletedTasks = TaskScheduler.Metrics.CompletedTasks + 1
		TaskScheduler:AddLog(self.Name .. " completed successfully.", self.Name)
		if self.OnComplete then
			self.OnComplete(self)
		end
	else
		self.Status = "failed"
		self.Error = result
		TaskScheduler.Metrics.FailedTasks = TaskScheduler.Metrics.FailedTasks + 1
		TaskScheduler:AddLog(self.Name .. " failed: " .. tostring(result), self.Name)
		if self.OnFail then
			self.OnFail(self)
		end
		TaskScheduler:RetryTask(self)
	end
end

function Task:Retry()
	if self.Retries < self.MaxRetries then
		self.Retries = self.Retries + 1
		TaskScheduler:AddLog(self.Name .. " retrying (" .. self.Retries .. "/" .. self.MaxRetries .. ")...", self.Name)
		wait(self.RetryDelay)
		self:Run()
	else
		TaskScheduler:AddLog(self.Name .. " failed after maximum retries.", self.Name)
		TaskScheduler:HandleGlobalError(self)
	end
end

function TaskScheduler:AddTask(name : string, func: () -> any, dependencies : {string}, priority : number, timeout : number, metadata)
	local task = Task.new(name, func, dependencies, priority, timeout, metadata)
	table.insert(self.Tasks, task)
	TaskScheduler.Metrics.TotalTasks = TaskScheduler.Metrics.TotalTasks + 1
	return task
end

function TaskScheduler:AddTaskToCategory(category, task)
	if not TaskScheduler.TaskCategories[category] then
		TaskScheduler.TaskCategories[category] = {}
	end
	table.insert(TaskScheduler.TaskCategories[category], task)
end

function TaskScheduler:AddTaskToNamespace(namespace, task)
	if not TaskScheduler.TaskNamespace[namespace] then
		TaskScheduler.TaskNamespace[namespace] = {}
	end
	table.insert(TaskScheduler.TaskNamespace[namespace], task)
end

function TaskScheduler:RunAll()
	TaskScheduler:SortTasksByPriority()

	while true do
		local ranTasks = false
		for _, task in ipairs(self.Tasks) do
			if TaskScheduler:CanRunTask() and task.Status == "queued" then
				TaskScheduler:IncrementRunningTasks()
				TaskScheduler:RunTask(task)
				ranTasks = true
			end
		end

		if not ranTasks then
			break
		end

		wait(0.1)
	end
end

function TaskScheduler:RunTask(task)
	if task.Status ~= "queued" then return end

	for _, depName in ipairs(task.Dependencies) do
		local depTask = TaskScheduler:GetTaskByName(depName)
		if not depTask or depTask.Status ~= "completed" then
			return
		end
	end

	task:Run()

	if task.Status == "failed" then
		TaskScheduler:RetryTask(task)
	elseif task.Status == "completed" then
		TaskScheduler:DecrementRunningTasks()
	end
end

function TaskScheduler:RetryTask(task)
	if task.RetryStrategy == TaskScheduler.RetryStrategies.Linear then
		task:Retry()
	elseif task.RetryStrategy == TaskScheduler.RetryStrategies.Exponential then
		task.RetryDelay = task.RetryDelay * 2
		task:Retry()
	elseif task.RetryStrategy == TaskScheduler.RetryStrategies.Jitter then
		task.RetryDelay = task.RetryDelay + math.random(0, 2)
		task:Retry()
	end
end

function TaskScheduler:GetTaskByName(name)
	for _, task in ipairs(TaskScheduler.Tasks) do
		if task.Name == name then
			return task
		end
	end
	return nil
end

function TaskScheduler:CancelTask(name)
	local task = TaskScheduler:GetTaskByName(name)
	if task then
		task.Status = "canceled"
		TaskScheduler:AddLog("Task " .. name .. " was canceled.", name)
	end
end

function TaskScheduler:PauseTask(name)
	local task = TaskScheduler:GetTaskByName(name)
	if task and task.Status == "running" then
		task.Status = "paused"
		TaskScheduler:AddLog("Task " .. name .. " was paused.", name)
	end
end

function TaskScheduler:ResumeTask(name)
	local task = TaskScheduler:GetTaskByName(name)
	if task and task.Status == "paused" then
		task.Status = "running"
		TaskScheduler:AddLog("Task " .. name .. " resumed.", name)
	end
end

function TaskScheduler:SortTasksByPriority()
	table.sort(TaskScheduler.Tasks, function(a, b)
		return a.Priority > b.Priority
	end)
end

function TaskScheduler:CanRunTask()
	return TaskScheduler.CurrentConcurrentTasks < TaskScheduler.MaxConcurrentTasks
end

function TaskScheduler:IncrementRunningTasks()
	TaskScheduler.CurrentConcurrentTasks = TaskScheduler.CurrentConcurrentTasks + 1
end

function TaskScheduler:DecrementRunningTasks()
	TaskScheduler.CurrentConcurrentTasks = TaskScheduler.CurrentConcurrentTasks - 1
end

function TaskScheduler:SetMaxConcurrentTasks(limit)
	TaskScheduler.MaxConcurrentTasks = limit
end

function TaskScheduler:RunGroup(groupName)
	local groupTasks = TaskScheduler.TaskGroups[groupName] or {}
	for _, task in ipairs(groupTasks) do
		TaskScheduler:RunTask(task)
	end
end

function TaskScheduler:AddTaskToGroup(groupName, task)
	TaskScheduler.TaskGroups[groupName] = TaskScheduler.TaskGroups[groupName] or {}
	table.insert(TaskScheduler.TaskGroups[groupName], task)
end

function TaskScheduler:HandleGlobalError(task)
	if TaskScheduler.GlobalErrorHandler then
		TaskScheduler.GlobalErrorHandler(task)
	end
end

function TaskScheduler:HandleThrottling(task)
	if task.ThrottleKey and TaskScheduler.ThrottlingRules[task.ThrottleKey] then
		local rule = TaskScheduler.ThrottlingRules[task.ThrottleKey]
		if rule.LastRun and tick() - rule.LastRun < rule.Interval then
			task.Status = "throttled"
			TaskScheduler:AddLog("Task " .. task.Name .. " throttled.", task.Name)
			wait(rule.Interval - (tick() - rule.LastRun))
		end
		rule.LastRun = tick()
	end
end

function TaskScheduler:AddThrottlingRule(key, interval)
	TaskScheduler.ThrottlingRules[key] = { Interval = interval, LastRun = nil }
end

function TaskScheduler:AddLog(message, taskName)
	TaskScheduler.Logs[#TaskScheduler.Logs + 1] = { Message = message, Task = taskName, Time = tick() }
end

function TaskScheduler:GetLogs()
	return TaskScheduler.Logs
end

function TaskScheduler:ClearLogs()
	TaskScheduler.Logs = {}
end

return TaskScheduler
