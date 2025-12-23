export const validateContact = (req, res, next) => {
  const { firstName, lastName } = req.body;
  if (!firstName || !lastName) {
    return res.status(400).json({ message: 'First name and last name are required' });
  }
  next();
};

export const validateLead = (req, res, next) => {
  const { firstName, lastName } = req.body;
  if (!firstName || !lastName) {
    return res.status(400).json({ message: 'First name and last name are required' });
  }
  next();
};

export const validateTask = (req, res, next) => {
  const { subject } = req.body;
  if (!subject) {
    return res.status(400).json({ message: 'Subject is required' });
  }
  next();
};

export const validateTicket = (req, res, next) => {
  const { subject } = req.body;
  if (!subject) {
    return res.status(400).json({ message: 'Subject is required' });
  }
  next();
};

export const validateOrganization = (req, res, next) => {
  const { name } = req.body;
  if (!name) {
    return res.status(400).json({ message: 'Name is required' });
  }
  next();
};

export const validateAccount = (req, res, next) => {
  const { name } = req.body;
  if (!name) {
    return res.status(400).json({ message: 'Account name is required' });
  }
  next();
};
