# TaskScheduler

The TaskScheduler module helps you easily manage and run multiple tasks at the same time. It's like a to-do list for your game, but way smarter. It lets you create tasks, set their priorities, track their progress, and even retry them if they fail. You can control how many tasks run at once, group them, or categorize them however you want.

# Key Features

- **Task Management:** Create tasks with custom functions and organize them into categories or groups.
- **Priorities & Dependencies:** You can set tasks to have a priority (Low, Normal, High) and also make tasks depend on other tasks.
- **Retries & Timeouts:** If a task fails, it can automatically retry based on different strategies (linear, exponential, or with random delays).
- **Throttling & Rate Limits:** Control how often tasks are allowed to run to avoid overloading your game.
- **Logging & Monitoring:** All tasks are tracked in logs so you can see what's happening and debug issues if needed.

# How it Works

- **Adding Tasks:** When you add a task, you provide a function that runs the task, set its priority, and can also add a timeout or metadata (extra info about the task).
- **Running Tasks:** Tasks can run in parallel (many at once) or in sequence (one at a time). The TaskScheduler automatically decides when to run tasks based on their priority and if they have any dependencies.
- **Task Retry System:** If a task fails, it will retry based on the strategy you’ve set (try again immediately, wait longer each time, or add a random delay).
- **Throttling:** Some tasks can be "throttled," meaning they can only run after a certain amount of time has passed, which is useful for rate-limiting tasks that shouldn't run too frequently.
- **Error Handling:** If a task keeps failing after all retries, the TaskScheduler can handle it globally and log the issue.

# Advantages of Using TaskScheduler Module vs Normal Functions

- **Task Prioritization:** TaskScheduler allows you to set task importance (Low, Normal, High), so important tasks get done first. Normal functions don't have this.
- **Managing Multiple Tasks:** TaskScheduler controls how many tasks run at the same time to prevent your game from slowing down. With normal functions, you'd have to manage this yourself.
- **Automatic Retries:** If a task fails, TaskScheduler can automatically try again using different retry methods. With normal functions, you'd need to write extra code to do this.
- **Task Dependencies:** You can make tasks wait for others to finish before running. Normal functions don't handle this easily.
- **Logging:** TaskScheduler keeps a log of what's happening with each task, making it easier to track and debug. Normal functions don’t automatically log events.
- **Throttling:** You can limit how often tasks run to prevent overuse, which isn't built into normal functions.
- **Task Grouping:** You can organize tasks into groups for better management. Normal functions can't do this without extra work.
  
# Disadvantages of Using TaskScheduler Module vs Normal Functions

- **More Code:** TaskScheduler adds extra steps and code, which might be unnecessary for simple tasks.
- **Complex Setup:** It can be harder to set up TaskScheduler compared to just using normal functions for basic tasks.
- **Learning Required:** You need to learn how to use TaskScheduler properly, while normal functions are easier to understand and use.
- **Uses More Memory:** TaskScheduler keeps track of tasks and logs, so it can use more memory than running simple functions.
- **Overkill for Simple Tasks:** For very basic actions, using TaskScheduler might be more complicated than just using a normal function.
