/**
 * CompleteTaskCommand
 * 
 * Marks a task as completed
 * Handles:
 *  - State transition validation
 *  - Completion timestamp
 *  - Dependent task notifications
 *  - Activity logging
 *  - Metrics update (future: dashboard impact)
 */

import prisma from '../../lib/prismaClient.js';
import { validateTaskTransition } from '../validators/stateMachineValidator.js';
import { getTaskParentEntity } from '../validators/taskValidator.js';

export class CompleteTaskCommand {
  constructor(taskId, userId, organizationId) {
    this.taskId = taskId;
    this.userId = userId;
    this.organizationId = organizationId;
  }

  /**
   * Execute the completion command
   * @returns {Promise<Object>} { task, parentEntity, message }
   * @throws {Error} If completion fails
   */
  async execute() {
    return await prisma.$transaction(
      async (tx) => {
        // Step 1: Fetch and validate task
        const task = await tx.task.findUnique({
          where: { id: this.taskId },
          include: {
            contact: true,
            account: true,
            lead: true,
            owner: true,
          },
        });

        if (!task) {
          throw new Error(`Task not found: ${this.taskId}`);
        }

        if (task.organizationId !== this.organizationId) {
          throw new Error(`Task does not belong to this organization`);
        }

        // Step 2: Validate state transition
        try {
          validateTaskTransition(task.status, 'COMPLETED', 'SYSTEM');
        } catch (err) {
          throw new Error(
            `Cannot complete task with status ${task.status}. ${err.message}`
          );
        }

        // Step 3: Update task to completed
        const updatedTask = await tx.task.update({
          where: { id: this.taskId },
          data: {
            status: 'COMPLETED',
            completedAt: new Date(),
            updatedAt: new Date(),
          },
          include: {
            contact: true,
            account: true,
            lead: true,
            owner: true,
          },
        });

        // Step 4: Get parent entity info
        const parentEntity = getTaskParentEntity(updatedTask);

        // Step 5: Log completion
        await tx.activityLog.create({
          data: {
            action: 'COMPLETE',
            entityType: 'TASK',
            entityId: task.id,
            description: `Task completed: ${task.subject}${
              parentEntity ? ` (${parentEntity.type}: ${parentEntity.name})` : ''
            }`,
            userId: this.userId,
            organizationId: this.organizationId,
            metadata: {
              taskId: task.id,
              subject: task.subject,
              priority: task.priority,
              parentEntityType: parentEntity?.type,
              parentEntityId: parentEntity?.id,
              completionTime: new Date(),
              previousStatus: task.status,
            },
          },
        });

        // Step 6: Check for dependent tasks (future feature)
        // In Phase 3, implement dependent task notifications

        return {
          success: true,
          task: updatedTask,
          parentEntity,
          message: `Task "${task.subject}" completed successfully`,
        };
      },
      {
        maxWait: 5000,
        timeout: 30000,
      }
    );
  }
}
