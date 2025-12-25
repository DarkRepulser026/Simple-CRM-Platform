/**
 * Phase 1 Validation Layer Tests
 * 
 * Run with: npm test test/validators/phase1.test.js
 */

import { expect } from 'chai';
import {
  validateTaskCreation,
  validateTaskUpdate,
  validateTaskRelationship,
} from '../../services/validators/taskValidator.js';
import {
  validateTicketTransition,
  validateLeadTransition,
  validateTaskTransition,
  isLeadTerminal,
  isTaskTerminal,
  getTicketAllowedNextStates,
  getLeadAllowedNextStates,
} from '../../services/validators/stateMachineValidator.js';

// ============================================================================
// TASK XOR VALIDATOR TESTS
// ============================================================================

describe('Task Entity Relationship Validator (XOR)', () => {
  describe('validateTaskRelationship', () => {
    it('should allow task linked to contact only', () => {
      const task = {
        contactId: 'contact-123',
        accountId: null,
        leadId: null,
      };
      expect(() => validateTaskRelationship(task)).not.to.throw();
    });

    it('should allow task linked to account only', () => {
      const task = {
        contactId: null,
        accountId: 'account-123',
        leadId: null,
      };
      expect(() => validateTaskRelationship(task)).not.to.throw();
    });

    it('should allow task linked to lead only', () => {
      const task = {
        contactId: null,
        accountId: null,
        leadId: 'lead-123',
      };
      expect(() => validateTaskRelationship(task)).not.to.throw();
    });

    it('should reject task with no parent entity', () => {
      const task = {
        contactId: null,
        accountId: null,
        leadId: null,
      };
      expect(() => validateTaskRelationship(task))
        .to.throw('exactly ONE entity')
        .and.to.throw('None provided');
    });

    it('should reject task with contact + account', () => {
      const task = {
        contactId: 'contact-123',
        accountId: 'account-123',
        leadId: null,
      };
      expect(() => validateTaskRelationship(task))
        .to.throw('XOR constraint')
        .and.to.throw('found 2');
    });

    it('should reject task with all three entities', () => {
      const task = {
        contactId: 'contact-123',
        accountId: 'account-123',
        leadId: 'lead-123',
      };
      expect(() => validateTaskRelationship(task))
        .to.throw('XOR constraint')
        .and.to.throw('found 3');
    });

    it('should handle undefined values correctly', () => {
      const task = {
        contactId: undefined,
        accountId: undefined,
        leadId: 'lead-123',
      };
      expect(() => validateTaskRelationship(task)).not.to.throw();
    });
  });

  describe('validateTaskCreation', () => {
    const validTask = {
      subject: 'Test Task',
      contactId: 'contact-123',
      accountId: null,
      leadId: null,
      organizationId: 'org-123',
      ownerId: 'user-123',
      priority: 'NORMAL',
      status: 'NOT_STARTED',
    };

    it('should validate complete task', () => {
      expect(() => validateTaskCreation(validTask)).not.to.throw();
    });

    it('should reject empty subject', () => {
      const task = { ...validTask, subject: '' };
      expect(() => validateTaskCreation(task))
        .to.throw('subject')
        .and.to.throw('required');
    });

    it('should reject missing subject', () => {
      const task = { ...validTask };
      delete task.subject;
      expect(() => validateTaskCreation(task))
        .to.throw('subject')
        .and.to.throw('required');
    });

    it('should reject missing organizationId', () => {
      const task = { ...validTask };
      delete task.organizationId;
      expect(() => validateTaskCreation(task))
        .to.throw('organization');
    });

    it('should reject missing ownerId', () => {
      const task = { ...validTask };
      delete task.ownerId;
      expect(() => validateTaskCreation(task))
        .to.throw('owner');
    });

    it('should reject invalid status', () => {
      const task = { ...validTask, status: 'INVALID' };
      expect(() => validateTaskCreation(task))
        .to.throw('Invalid task status');
    });

    it('should reject invalid priority', () => {
      const task = { ...validTask, priority: 'CRITICAL' };
      expect(() => validateTaskCreation(task))
        .to.throw('Invalid task priority');
    });

    it('should accept null optional fields', () => {
      const task = {
        subject: 'Test',
        contactId: 'contact-123',
        accountId: null,
        leadId: null,
        organizationId: 'org-123',
        ownerId: 'user-123',
        // priority and status undefined
      };
      expect(() => validateTaskCreation(task)).not.to.throw();
    });
  });

  describe('validateTaskUpdate', () => {
    const existingTask = {
      contactId: 'contact-123',
      accountId: null,
      leadId: null,
      status: 'NOT_STARTED',
      priority: 'NORMAL',
    };

    it('should allow status update only', () => {
      expect(() => validateTaskUpdate(existingTask, { status: 'IN_PROGRESS' }))
        .not.to.throw();
    });

    it('should allow relationship change to different entity', () => {
      const updates = {
        contactId: null,
        accountId: 'account-123',
        leadId: null,
      };
      expect(() => validateTaskUpdate(existingTask, updates)).not.to.throw();
    });

    it('should reject relationship change to multiple entities', () => {
      const updates = {
        contactId: 'contact-456',
        accountId: 'account-123',
        leadId: null,
      };
      expect(() => validateTaskUpdate(existingTask, updates))
        .to.throw('XOR constraint');
    });

    it('should allow undefined updates', () => {
      expect(() => validateTaskUpdate(existingTask, { subject: 'New subject' }))
        .not.to.throw();
    });

    it('should reject invalid status', () => {
      expect(() => validateTaskUpdate(existingTask, { status: 'INVALID' }))
        .to.throw('Invalid task status');
    });
  });
});

// ============================================================================
// TICKET STATE MACHINE TESTS
// ============================================================================

describe('Ticket State Machine Validator', () => {
  describe('validateTicketTransition', () => {
    it('should allow OPEN → IN_PROGRESS', () => {
      expect(() => validateTicketTransition('OPEN', 'IN_PROGRESS', 'AGENT'))
        .not.to.throw();
    });

    it('should allow OPEN → CLOSED', () => {
      expect(() => validateTicketTransition('OPEN', 'CLOSED', 'AGENT'))
        .not.to.throw();
    });

    it('should allow IN_PROGRESS → RESOLVED', () => {
      expect(() => validateTicketTransition('IN_PROGRESS', 'RESOLVED', 'AGENT'))
        .not.to.throw();
    });

    it('should allow IN_PROGRESS → OPEN', () => {
      expect(() => validateTicketTransition('IN_PROGRESS', 'OPEN', 'AGENT'))
        .not.to.throw();
    });

    it('should allow RESOLVED → CLOSED', () => {
      expect(() => validateTicketTransition('RESOLVED', 'CLOSED', 'AGENT'))
        .not.to.throw();
    });

    it('should reject CLOSED → RESOLVED (terminal)', () => {
      expect(() => validateTicketTransition('CLOSED', 'RESOLVED', 'AGENT'))
        .to.throw('Cannot transition');
    });

    it('should reject invalid transitions for non-admin', () => {
      expect(() => validateTicketTransition('OPEN', 'RESOLVED', 'AGENT'))
        .to.throw('Cannot transition');
    });

    it('should allow admin to override transitions', () => {
      expect(() => validateTicketTransition('OPEN', 'RESOLVED', 'ADMIN'))
        .not.to.throw();
    });

    it('should allow no-op transitions', () => {
      expect(() => validateTicketTransition('OPEN', 'OPEN', 'AGENT'))
        .not.to.throw();
    });
  });

  describe('getTicketAllowedNextStates', () => {
    it('should return allowed states from OPEN', () => {
      const states = getTicketAllowedNextStates('OPEN');
      expect(states).to.deep.equal(['IN_PROGRESS', 'CLOSED']);
    });

    it('should return empty array for CLOSED', () => {
      const states = getTicketAllowedNextStates('CLOSED');
      expect(states).to.be.empty;
    });
  });
});

// ============================================================================
// LEAD STATE MACHINE TESTS
// ============================================================================

describe('Lead State Machine Validator', () => {
  describe('validateLeadTransition', () => {
    it('should allow NEW → PENDING', () => {
      expect(() => validateLeadTransition('NEW', 'PENDING', 'AGENT', false))
        .not.to.throw();
    });

    it('should allow NEW → CONTACTED', () => {
      expect(() => validateLeadTransition('NEW', 'CONTACTED', 'AGENT', false))
        .not.to.throw();
    });

    it('should allow QUALIFIED → CONVERTED', () => {
      expect(() => validateLeadTransition('QUALIFIED', 'CONVERTED', 'AGENT', false))
        .not.to.throw();
    });

    it('should block edits on converted lead for non-admin', () => {
      expect(() =>
        validateLeadTransition('CONVERTED', 'UNQUALIFIED', 'AGENT', true)
      ).to.throw('Cannot modify a converted lead');
    });

    it('should allow admin to edit converted lead', () => {
      expect(() =>
        validateLeadTransition('CONVERTED', 'UNQUALIFIED', 'ADMIN', true)
      ).not.to.throw();
    });

    it('should reject invalid transitions for non-admin', () => {
      expect(() => validateLeadTransition('QUALIFIED', 'PENDING', 'AGENT', false))
        .to.throw('Cannot transition');
    });

    it('should allow admin override', () => {
      expect(() => validateLeadTransition('QUALIFIED', 'PENDING', 'ADMIN', false))
        .not.to.throw();
    });
  });

  describe('isLeadTerminal', () => {
    it('should identify CONVERTED as terminal', () => {
      expect(isLeadTerminal('CONVERTED')).to.be.true;
    });

    it('should identify UNQUALIFIED as terminal', () => {
      expect(isLeadTerminal('UNQUALIFIED')).to.be.true;
    });

    it('should identify NEW as non-terminal', () => {
      expect(isLeadTerminal('NEW')).to.be.false;
    });
  });

  describe('getLeadAllowedNextStates', () => {
    it('should return states from NEW', () => {
      const states = getLeadAllowedNextStates('NEW');
      expect(states).to.include('PENDING', 'CONTACTED', 'UNQUALIFIED');
    });

    it('should return empty for CONVERTED', () => {
      const states = getLeadAllowedNextStates('CONVERTED');
      expect(states).to.be.empty;
    });
  });
});

// ============================================================================
// TASK STATE MACHINE TESTS
// ============================================================================

describe('Task State Machine Validator', () => {
  describe('validateTaskTransition', () => {
    it('should allow NOT_STARTED → IN_PROGRESS', () => {
      expect(() => validateTaskTransition('NOT_STARTED', 'IN_PROGRESS', 'AGENT'))
        .not.to.throw();
    });

    it('should allow IN_PROGRESS → COMPLETED', () => {
      expect(() => validateTaskTransition('IN_PROGRESS', 'COMPLETED', 'AGENT'))
        .not.to.throw();
    });

    it('should reject COMPLETED → IN_PROGRESS', () => {
      expect(() => validateTaskTransition('COMPLETED', 'IN_PROGRESS', 'AGENT'))
        .to.throw('Cannot transition');
    });

    it('should allow admin override', () => {
      expect(() => validateTaskTransition('COMPLETED', 'IN_PROGRESS', 'ADMIN'))
        .not.to.throw();
    });
  });

  describe('isTaskTerminal', () => {
    it('should identify COMPLETED as terminal', () => {
      expect(isTaskTerminal('COMPLETED')).to.be.true;
    });

    it('should identify CANCELLED as terminal', () => {
      expect(isTaskTerminal('CANCELLED')).to.be.true;
    });

    it('should identify IN_PROGRESS as non-terminal', () => {
      expect(isTaskTerminal('IN_PROGRESS')).to.be.false;
    });
  });
});
