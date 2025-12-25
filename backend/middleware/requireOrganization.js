export const requireOrganization = (req, res, next) => {
  const orgId = req.headers['x-organization-id'];
  if (!orgId) {
    return res.status(400).json({ message: 'Organization ID required' });
  }
  req.organizationId = orgId;
  next();
};
