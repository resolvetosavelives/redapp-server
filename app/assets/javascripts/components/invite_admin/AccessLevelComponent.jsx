class AccessLevelComponent extends React.Component {

    render() {
        var selectFacilityGroups = this.props.required_resources.includes('FacilityGroup')
            ? <SelectResource resourceType='FacilityGroup'
                              resources={this.props.facility_groups}
                              updateResources={this.props.updateResources}
                              organization_id={this.props.organization_id}
                              selected_resources={this.props.selected_resources}/>
            : null;

        return (
            <div>
                <div className="form-group row">
                    <label htmlFor="access-input" className="col-md-2 col-form-label">Access level</label>
                    <div className="col-md-10">
                        <SelectField name="accessLevel"
                                     selected_level={this.props.selected_level}
                                     updateAccessLevel={this.props.updateAccessLevel}
                                     access_levels={this.props.access_levels}/>
                        <CollectionCheckBoxes permissions={this.props.permissions}
                                              selected_permissions={this.props.selected_permissions}
                                              updatePermissions={this.props.updatePermissions}/>
                    </div>
                </div>
                {selectFacilityGroups}
            </div>
        )
    }
}